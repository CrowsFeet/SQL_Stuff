use master
GO

--BACKUP DATABASE [<DBName_Here>] -- 1min 46s
--TO DISK = N'C:\Temp\Backup\<DBName_Here>_201710181457_001.bak',
--   DISK = N'C:\Temp\Backup\<DBName_Here>_201710181457_002.bak'
--WITH INIT,COMPRESSION,STATS=10

--BACKUP DATABASE [<DBName_Here>]
--TO DISK = N'C:\Temp\Backup\<DBName_Here>_201710181456_001.bak',
--   DISK = N'C:\Temp\Backup\<DBName_Here>_201710181456_002.bak',
--   DISK = N'C:\Temp\Backup\<DBName_Here>_201710181456_003.bak',
--   DISK = N'C:\Temp\Backup\<DBName_Here>_201710181456_004.bak'
--WITH INIT,COMPRESSION,STATS=10



RESTORE FILELISTONLY
FROM DISK = N'C:\Temp\Backup\<DBName_Here>_FULL_20171101010051.bak'

RESTORE DATABASE [<DBName_Here>]
FROM DISK = N'C:\Temp\Backup\<DBName_Here>_FULL_20171101010051.bak'
WITH FILE = 1,
MOVE N'Horizon' TO N'C:\Temp\Data\<DBName_Here>_Data.mdf',
MOVE N'Horizon_log' TO N'C:\Temp\Log\<DBName_Here>_Log.ldf',
NORECOVERY,REPLACE,STATS=10

RESTORE DATABASE [<DBName_Here>]
FROM DISK = N'C:\Temp\Backup\<DBName_Here>_DIFF_20171101130022.bak'
WITH FILE = 1,
MOVE N'Horizon' TO N'C:\Temp\\Data\<DBName_Here>_Data.mdf',
MOVE N'Horizon_log' TO N'C:\Temp\Log\<DBName_Here>_Log.ldf',
RECOVERY,REPLACE,STATS=10




