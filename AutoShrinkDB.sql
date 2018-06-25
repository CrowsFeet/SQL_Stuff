SET NOCOUNT ON

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Please note that I do not recommend auto shrinking databases (log files yes, data files no).
--
-- Author :		Andy G
--
-- Created :	13/04/2017
--
-- History :
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @LogicalFileName NVARCHAR(255),
		@FileSize BIGINT,
		@FreeSpace BIGINT,
		@PctFree DECIMAL(10,2)

DECLARE @Table1 TABLE
(
	ServerName NVARCHAR(255),
	DatabaseName NVARCHAR(255),
	LogicalFileName NVARCHAR(255),
	PhysicalFileName NVARCHAR(255),
	FileSize BIGINT,
	FreeSpaceMB BIGINT,
	FreeSpacePct DECIMAL(10,2) --NVARCHAR(10)
)
INSERT INTO @Table1 (ServerName,DatabaseName,LogicalFileName,PhysicalFileName,FileSize,FreeSpaceMB,FreeSpacePct)
SELECT  
@@servername as ServerName,  
'HZN_HEATONS' AS DatabaseName,  
sysfiles.name AS LogicalFileName, 
sysfiles.filename AS PhysicalFileName,  
CAST(sysfiles.size/128.0 AS int) AS FileSize,  
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, 'SpaceUsed' ) AS int)/128.0 AS int) AS FreeSpaceMB,  
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  'SpaceUsed') AS int)/128.0)/(sysfiles.size/128.0)) AS decimal(4,2))) AS varchar(8))  AS FreeSpacePct
FROM dbo.sysfiles

-- Clear down table
--TRUNCATE TABLE ENTRY_EXTRA

-- Shrink Log file
SELECT 
	@LogicalFileName  = LogicalFileName,
	@FileSize = FileSize,
	@PctFree = FreeSpacePct
FROM @Table1
WHERE LogicalFileName LIKE '%_log'

-- Only want to shrink the log file if it reaches a specific threshold
IF @PctFree > 90.00 AND @FileSize > 1024
BEGIN
	DBCC SHRINKFILE (@LogicalFileName, 1024) WITH NO_INFOMSGS; -- param is the logical file name and the number is the size you want to shrink it to.

	PRINT 'Completed Log File Shrink'
END

-- Shrink Data file
-- restate the parameter now for the data file
SELECT 
	@LogicalFileName  = LogicalFileName,
	@FileSize = FileSize,
	@PctFree = FreeSpacePct
FROM @Table1
WHERE LogicalFileName NOT LIKE '%_log'

SET @FileSize = 0

-- leave 10% free in the db
WHILE @PctFree > 10.10
BEGIN

	-- reduce the DB by 1Gb increments.
	SELECT @LogicalFileName = LogicalFileName, @FileSize = FileSize - 1024 FROM @Table1 WHERE LogicalFileName NOT LIKE '%_log'

	DBCC SHRINKFILE (@LogicalFileName, @FileSize) WITH NO_INFOMSGS; -- param is the logical file name and the number is the size you want to shrink it to.

	SELECT  
		@LogicalFileName = sysfiles.name, 
		@FileSize = CAST(sysfiles.size/128.0 AS int),	
		@PctFree = CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  'SpaceUsed') AS int)/128.0)/(sysfiles.size/128.0)) AS decimal(4,2))) AS varchar(8))
	FROM dbo.sysfiles
	WHERE sysfiles.name NOT LIKE '%_log'

	PRINT @PctFree

	UPDATE @Table1
	SET FreeSpacePct = @PctFree,
	FileSize = @FileSize
	WHERE LogicalFileName = @LogicalFileName

	SELECT 
		@LogicalFileName  = LogicalFileName,
		@FileSize = FileSize,
		@PctFree = FreeSpacePct
	FROM @Table1
	WHERE LogicalFileName NOT LIKE '%_log'

	--Print @PctFree

	PRINT 'Completed Data File Shrink'
END

