SET NOCOUNT ON

DROP TABLE #Tmp_Test_001
DROP TABLE ##tmpBulk
TRUNCATE TABLE TMPVOW

CREATE TABLE #Tmp_Test_001(columnNames VARCHAR(MAX));
BULK INSERT #Tmp_Test_001
FROM 'C:\Temp\ImportFile\22403_catalogue.csv'
WITH (FIRSTROW = 1, LASTROW = 1, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

--SELECT * FROM #Tmp_Test_001

--SELECT '[' + REPLACE(columnNames,',','],[') +']'
--FROM #Tmp_Test_001

UPDATE #Tmp_Test_001
SET columnNames = '[' + REPLACE(REPLACE(columnNames,',','],['),' ','_') +']' -- My OCD and hatred of column names with spaces in them.

--SELECT * FROM #Tmp_Test_001

DECLARE @sql AS VARCHAR(MAX)
SELECT @sql = 'create table ##tmpBulk (' + replace(columnNames,',',' varchar(1000),') + ' varchar(1000));
				bulk insert ##tmpBulk
				from ''C:\Temp\ImportFile\22403_catalogue.csv''
				with (FirstRow = 2, FieldTerminator = '','', RowTerminator = ''\n'');
				--select * from ##tmpBulk'
FROM #Tmp_Test_001

--PRINT @SQL

EXEC(@sql)    


--SELECT c.name FROM tempdb.sys.columns c INNER JOIN tempdb.sys.tables t ON c.object_id = t.object_id WHERE t.name LIKE '##tmpBulk%' AND column_id = 1

--SELECT STUFF(
--(SELECT 
--',' + c.name AS [text()]
--FROM tempdb.sys.columns c INNER JOIN tempdb.sys.tables t ON c.object_id = t.object_id WHERE t.name LIKE '##tmpBulk%' 
----Order By Ordinal_position
--FOR XML PATH('')
--), 1,1, '')


INSERT INTO TMPVOW (CODE,STOCK)
SELECT 
'[' + (SELECT c.name FROM tempdb.sys.columns c INNER JOIN tempdb.sys.tables t ON c.object_id = t.object_id WHERE t.name LIKE '##tmpBulk%' AND column_id = 1) + ']' ,
STOCK
FROM ##tmpBulk


SELECT * FROM TMPVOW



--SELECT * FROM ##tmpBulk


/*

-- Get a comma separated list of a table's column names
SELECT STUFF(
(SELECT 
',' + COLUMN_NAME AS [text()]
FROM 
INFORMATION_SCHEMA.COLUMNS
WHERE 
TABLE_NAME = 'TableName'
Order By Ordinal_position
FOR XML PATH('')
), 1,1, '')

*/