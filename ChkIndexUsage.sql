 -- more useful indexy type scripts.
USE <DBName_Here>
go
-- index used for inserts updates and deletes
SELECT OBJECT_NAME(A.[OBJECT_ID]) AS [OBJECT NAME], 
       I.[NAME] AS [INDEX NAME], 
       A.LEAF_INSERT_COUNT, 
       A.LEAF_UPDATE_COUNT, 
       A.LEAF_DELETE_COUNT 
FROM   SYS.DM_DB_INDEX_OPERATIONAL_STATS (db_id(),NULL,NULL,NULL ) A 
       INNER JOIN SYS.INDEXES AS I 
         ON I.[OBJECT_ID] = A.[OBJECT_ID] 
            AND I.INDEX_ID = A.INDEX_ID 
WHERE  OBJECTPROPERTY(A.[OBJECT_ID],'IsUserTable') = 1

-- index used by user queries
-- lookups should be avoided
SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
       I.[NAME] AS [INDEX NAME], 
       USER_SEEKS, 
       USER_SCANS, 
       USER_LOOKUPS, 
       USER_UPDATES 
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S 
       INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
       AND S.database_id = DB_ID()

----------------------------------------------------------------------------------------------------------------

    -- Index Read/Write stats for a single table
    SELECT OBJECT_NAME(s.[object_id]) AS [TableName], 
    i.name AS [IndexName], i.index_id,
    SUM(user_seeks) AS [User Seeks], SUM(user_scans) AS [User Scans], 
    SUM(user_lookups)AS [User Lookups],
    SUM(user_seeks + user_scans + user_lookups)AS [Total Reads], 
    SUM(user_updates) AS [Total Writes]     
    FROM sys.dm_db_index_usage_stats AS s
    INNER JOIN sys.indexes AS i
    ON s.[object_id] = i.[object_id]
    AND i.index_id = s.index_id
    WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
    AND s.database_id = DB_ID()
    AND OBJECT_NAME(s.[object_id]) = N'ActivityEventMeta'
    GROUP BY OBJECT_NAME(s.[object_id]), i.name, i.index_id
    ORDER BY [Total Writes] DESC, [Total Reads] DESC;

-------------------------------------------------------------------------------------------------------------------------

SELECT OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
       I.[NAME] AS [INDEX NAME], 
       USER_SEEKS, 
       USER_SCANS, 
       USER_LOOKUPS, 
       USER_UPDATES,
--	   SUM(pa.rows) RowCnt, -- not accurate at all
	   (SELECT TOP 1 rowcnt FROM sysindexes WHERE id = i.object_id) RowCnt
--	   SUM(ps.row_count) AS tableRowCount
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S 
       INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
--	   CROSS APPLY sys.dm_db_partition_stats st 
--	   INNER JOIN sys.dm_db_partition_stats AS ps ON OBJECT_NAME(S.[OBJECT_ID]) = ps.object_id
--	CROSS APPLY (SELECT COUNT(*) FROM OBJECT_NAME(S.[OBJECT_ID])) a
INNER JOIN sys.partitions pa ON pa.OBJECT_ID = s.OBJECT_ID
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
       AND S.database_id = DB_ID()
GROUP BY        
	s.OBJECT_ID,
	I.[NAME],
	USER_SEEKS, 
	USER_SCANS, 
	USER_LOOKUPS, 
	USER_UPDATES,
	i.OBJECT_ID
ORDER BY S.user_updates



-- Possible Bad NC Indexes (writes > reads)
SELECT OBJECT_NAME(s.[object_id]) AS [Table Name] , 
i.name AS [Index Name] , 
i.index_id , 
user_updates AS [Total Writes] , 
user_seeks + user_scans + user_lookups AS [Total Reads] , 
user_updates - ( user_seeks + user_scans + user_lookups ) 
AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH ( NOLOCK ) 
INNER JOIN sys.indexes AS i WITH ( NOLOCK ) 
ON s.[object_id] = i.[object_id] 
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1 
AND s.database_id = DB_ID() 
AND user_updates > ( user_seeks + user_scans + user_lookups ) 
AND i.index_id > 1
ORDER BY [Difference] DESC , 
[Total Writes] DESC , 
[Total Reads] ASC ;
