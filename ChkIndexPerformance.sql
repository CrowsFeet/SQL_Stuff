use <DBName_Here>
go
-- shows index usage
SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], I.INDEX_ID ,
       I.[NAME] AS [INDEX NAME], 
       USER_SEEKS, 
       USER_SCANS, 
       USER_LOOKUPS, 
       USER_UPDATES 
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S 
       INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
       AND S.database_id = DB_ID()
	   --AND i.name LIKE '%-%'
ORDER BY 4

--SELECT * FROM dbo.sic_sicCodeLookup
--SELECT * FROM dbo.dimTime


--SELECT * FROM dbo.mfr_MappingForUrlRedirects

/*
SELECT 
    i.name 'Index Name',
    o.create_date
FROM 
    sys.indexes i
INNER JOIN 
    sys.objects o ON i.name = o.name
WHERE 
    o.is_ms_shipped = 0
    AND o.type IN ('PK', 'FK', 'UQ')

SELECT * FROM sys.sysobjects
WHERE name LIKE '%-%'
*/

