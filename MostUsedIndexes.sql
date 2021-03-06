-- lists the index usage on a database
SELECT 
	db_name(ius.database_id) AS DatabaseName,
	t.NAME AS TableName,
	i.NAME AS IndexName,
	i.type_desc AS IndexType,
	ius.user_seeks + ius.user_scans + ius.user_lookups AS NbrTimesAccessed
FROM sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes i ON i.OBJECT_ID = ius.OBJECT_ID AND i.index_id = ius.index_id
INNER JOIN sys.tables t ON t.OBJECT_ID = i.object_id
WHERE database_id = DB_ID('<Add DB Name Here>')
ORDER BY ius.user_seeks + ius.user_scans + ius.user_lookups DESC
