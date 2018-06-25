SELECT 
	DB_NAME() AS DatabaseName
	,OBJECT_NAME(S.[OBJECT_ID]) AS TableName
	,I.[NAME] AS IndexName
	, (s.user_seeks + s.user_scans + s.user_lookups) AS [Usage]
	, s.user_updates
--       USER_SEEKS, 
--       USER_SCANS, 
--       USER_LOOKUPS, 
--       USER_UPDATES 
FROM   SYS.DM_DB_INDEX_USAGE_STATS AS S 
       INNER JOIN SYS.INDEXES AS I ON I.[OBJECT_ID] = S.[OBJECT_ID] AND I.INDEX_ID = S.INDEX_ID 
WHERE  OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1
       AND S.database_id = DB_ID()
ORDER BY 2,3,4 asc