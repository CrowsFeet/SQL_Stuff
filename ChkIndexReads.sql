-- Check when an index was last used
--select * from  sys.dm_db_index_usage_stats

SELECT dbschemas.[name] as 'Schema', 
dbtables.[name] as 'Table', 
dbindexes.[name] as 'Index',
STATS_DATE(dbindexes.OBJECT_ID, dbindexes.index_id) AS StatsUpdated,
last_user_seek,
last_user_scan,
last_user_lookup,
last_user_update,
last_system_seek,
last_system_scan,
last_system_lookup,
last_system_update
FROM sys.dm_db_index_usage_stats indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
