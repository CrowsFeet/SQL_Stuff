-- I have an automated process that does this, but this is the manual version.
set nocount on

DECLARE @Table1 TABLE
(
name NVARCHAR(255),
Schema_Nom NVARCHAR(255), 
Table_Name NVARCHAR(255), 
Index_Name NVARCHAR(255),
StatsUpdated DATETIME,
fragment_count INT,
avg_fragmentation_in_percent FLOAT,
avg_page_space_used_in_percent FLOAT,
page_count INT,
RowCounts INT,
Indexme NVARCHAR(1000),
UpdateMe NVARCHAR(255)
)

INSERT INTO @Table1 (name,Schema_Nom,Table_Name,Index_Name,StatsUpdated,fragment_count,avg_fragmentation_in_percent,avg_page_space_used_in_percent,page_count,RowCounts,Indexme,UpdateMe)
SELECT 
sd.name,
dbschemas.[name] AS Schema_Nom, 
dbtables.[name] AS Table_Name,
dbindexes.[name] AS Index_Name,
STATS_DATE(dbindexes.OBJECT_ID, dbindexes.index_id) AS StatsUpdated,
indexstats.fragment_count,
convert(decimal(8,2),indexstats.avg_fragmentation_in_percent) as avg_fragmentation_in_percent,
indexstats.avg_page_space_used_in_percent,
indexstats.page_count,
p.rows AS RowCounts,
CASE WHEN indexstats.avg_fragmentation_in_percent >10 THEN 'ALTER INDEX ' + dbindexes.[name] + ' ON ' + dbschemas.[name] + '.' + dbtables.[name] + ' REBUILD ' + CHAR(13)+CHAR(10) + ' GO' --with (sort_in_tempdb = ON)'
--	 WHEN indexstats.avg_fragmentation_in_percent >= 10 AND indexstats.avg_fragmentation_in_percent <= 30 THEN 'ALTER INDEX ' + dbindexes.[name] + ' ON ' + dbschemas.[name] + '.' + dbtables.[name] + ' REBUILD ' + CHAR(13)+CHAR(10) + ' GO'--reorganize '-- with(sort_in_tempdb = ON)'
ELSE NULL END AS Indexme,
'UPDATE STATISTICS ' + dbtables.[name] AS UpdateMe
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
--FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'DETAILED') AS indexstats
LEFT OUTER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
LEFT OUTER JOIN sys.schemAS dbschemAS on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id] AND indexstats.index_id = dbindexes.index_id
INNER JOIN sys.partitions p ON dbindexes.object_id = p.OBJECT_ID AND dbindexes.index_id = p.index_id
LEFT OUTER JOIN sys.sysdatabases sd on sd.dbid = DB_ID()
WHERE indexstats.database_id = DB_ID()
--and indexstats.avg_fragmentation_in_percent > 10
AND dbindexes.[name] IS NOT NULL
--AND 9 IS NOT NULL
AND dbindexes.is_disabled = 0
--ORDER BY indexstats.avg_fragmentation_in_percent DESC
ORDER BY dbtables.[name],dbindexes.[name]
OPTION (HASH GROUP)



SELECT DISTINCT 
* 
FROM @Table1
WHERE Indexme IS NOT NULL



SELECT 'UPDATE STATISTICS dbo.[' + name + '];' FROM sys.tables
ORDER BY name
