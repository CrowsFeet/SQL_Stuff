-- change the mirror timeout limit. the default is 30 I believe.
USE master
GO
ALTER DATABASE dbName SET PARTNER TIMEOUT 20
