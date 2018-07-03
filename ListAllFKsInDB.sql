-- SQL Stored quite a lot of data. some of it more useful than others.
-- here is another useful one.
SET NOCOUNT ON

DECLARE @SQL1 NVARCHAR(4000),
		@DatabaseName NVARCHAR(255)

IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects o WHERE o.xtype in ('U') AND o.id = object_id(N'tempdb..##tmp_AG1'))
DROP TABLE ##tmp_AG1

CREATE TABLE ##tmp_AG1
(
ServerName NVARCHAR(255),
DatabaseName NVARCHAR(255),
ForeignKey NVARCHAR(255)
)

DECLARE @Table1 TABLE
(
	DBName NVARCHAR(255),
	Completed INT
)
INSERT INTO @Table1 (DBName,Completed)
SELECT 
name AS DBName,
0 AS Completed
FROM sys.databases
WHERE name like '%<DBName_Here%'
AND state_desc = 'ONLINE'
ORDER BY name


WHILE EXISTS (SELECT DBName FROM @Table1 WHERE Completed = 0)
BEGIN

	SELECT 
		@DatabaseName = DBName
	FROM @Table1
	WHERE Completed = 0

	SET @SQL1 = '
	USE [' + @DatabaseName + ']

	INSERT INTO ##tmp_AG1 (ServerName,DatabaseName,ForeignKey)
	SELECT 
		@@SERVERNAME AS ServerName,
		DB_NAME() AS DatabaseName,
		f.name AS ForeignKey 
	FROM sys.foreign_keys AS f 
	INNER JOIN sys.foreign_key_columns AS fc 
	   ON f.OBJECT_ID = fc.constraint_object_id
	ORDER BY f.name
	'
print @SQL1
EXEC sp_executeSQL @SQL1

	UPDATE @Table1
	SET Completed = 1
	WHERE DBName = @DatabaseName

END


SELECT * FROM ##tmp_AG1

DROP TABLE ##tmp_AG1
