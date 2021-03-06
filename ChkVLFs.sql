-- another first of many. this will check the VLF's of all databases on a server.
SET NOCOUNT ON;

/* declare variables required */

DECLARE @DatabaseId INT;
DECLARE @TSQL VARCHAR(MAX);
DECLARE cur_DBs CURSOR
FOR
    SELECT  database_id
    FROM    sys.databases;

OPEN cur_DBs;

FETCH NEXT FROM cur_DBs INTO @DatabaseId
--These table variables will be used to store the data

DECLARE @tblAllDBs TABLE
    (
      DBName sysname ,
      FileId INT ,
      FileSize BIGINT ,
      StartOffset BIGINT ,
      FSeqNo INT ,
      Status TINYINT ,
      Parity INT ,
      CreateLSN NUMERIC(25, 0)
    )

IF '11' = SUBSTRING(CONVERT(CHAR(12), SERVERPROPERTY('productversion')), 1, 2)
    BEGIN

        DECLARE @tblVLFs2012 TABLE
            (
              RecoveryUnitId BIGINT ,
              FileId INT ,
              FileSize BIGINT ,
              StartOffset BIGINT ,
              FSeqNo INT ,
              Status TINYINT ,
              Parity INT ,
              CreateLSN NUMERIC(25, 0)
            );
    END
ELSE
    BEGIN
        DECLARE @tblVLFs TABLE
            (
              FileId INT ,
              FileSize BIGINT ,
              StartOffset BIGINT ,
              FSeqNo INT ,
              Status TINYINT ,
              Parity INT ,
              CreateLSN NUMERIC(25, 0)
            );
    END

--loop through each database and get the info

WHILE @@FETCH_STATUS = 0
    BEGIN

        PRINT 'DB: ' + CONVERT(VARCHAR(200), DB_NAME(@DatabaseId));

        SET @TSQL = 'dbcc loginfo(' + CONVERT(VARCHAR(12), @DatabaseId) + ');';

        IF '11' = SUBSTRING(CONVERT(CHAR(12), SERVERPROPERTY('productversion')),
                            1, 2)
            BEGIN
                DELETE  FROM @tblVLFs2012;
                INSERT  INTO @tblVLFs2012
                        EXEC ( @TSQL
                            );

                INSERT  INTO @tblAllDBs
                        SELECT  DB_NAME(@DatabaseId) ,
                                FileId ,
                                FileSize ,
                                StartOffset ,
                                FSeqNo ,
                                Status ,
                                Parity ,
                                CreateLSN
                        FROM    @tblVLFs2012;

            END

        ELSE
            BEGIN

                DELETE  FROM @tblVLFs;

                INSERT  INTO @tblVLFs
                        EXEC ( @TSQL
                            );

                INSERT  INTO @tblAllDBs
                        SELECT  DB_NAME(@DatabaseId) ,
                                FileId ,
                                FileSize ,
                                StartOffset ,
                                FSeqNo ,
                                Status ,
                                Parity ,
                                CreateLSN
                        FROM    @tblVLFs;

            END

        FETCH NEXT FROM cur_DBs INTO @DatabaseId

    END

CLOSE cur_DBs;

DEALLOCATE cur_DBs;

--just for formating if output to Text

PRINT '';

PRINT '';

PRINT '';

--Return the data based on what we have found

SELECT  a.DBName ,
        COUNT(a.FileId) AS [TotalVLFs] ,
        MAX(b.[ActiveVLFs]) AS [ActiveVLFs] ,
        ( SUM(a.FileSize) / COUNT(a.FileId) / 1024 ) AS [AvgFileSizeKb]
FROM    @tblAllDBs a
        INNER JOIN ( SELECT DBName ,
                            COUNT(FileId) [ActiveVLFs]
                     FROM   @tblAllDBs
                     WHERE  Status = 2
                     GROUP BY DBName
                   ) b ON b.DBName = a.DBName
GROUP BY a.DBName
ORDER BY TotalVLFs DESC;

 
