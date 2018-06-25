SELECT 'ALTER DATABASE tempdb MODIFY FILE (NAME = [' + f.name + '],'
	+ ' FILENAME = ''D:\DATA\' + f.name
	+ CASE WHEN f.type = 1 THEN '.ldf' ELSE '.mdf' END
	+ ''');'
FROM sys.master_files f
WHERE f.database_id = DB_ID(N'tempdb');

--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev], FILENAME = 'D:\DATA\tempdev.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [templog], FILENAME = 'D:\DATA\templog.ldf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev2], FILENAME = 'D:\DATA\tempdev2.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev3], FILENAME = 'D:\DATA\tempdev3.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev4], FILENAME = 'D:\DATA\tempdev4.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev5], FILENAME = 'D:\DATA\tempdev5.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev6], FILENAME = 'D:\DATA\tempdev6.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev7], FILENAME = 'D:\DATA\tempdev7.mdf');
--ALTER DATABASE tempdb MODIFY FILE (NAME = [tempdev8], FILENAME = 'D:\DATA\tempdev8.mdf');
