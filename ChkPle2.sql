-- another one that shows page life expectancy.

--select SUM(aggregated_record_length_in_bytes) [SpaceUsed] from sys.dm_tran_top_version_generators
--GROUP by database_id
--ORDER by SpaceUsed DESC

-- newer versio using DMV
--select convert(numeric(10,2),round(sum(data_pages)*8/1024.,2)) as user_object_reserved_MB
--from tempdb.sys.allocation_units a
--inner join tempdb.sys.partitions b on a.container_id = b.partition_id
--inner join tempdb.sys.objects c on b.object_id = c.object_id

--SELECT 
--object_name, 
--counter_name, 
--cntr_value,
--cntr_value
--FROM sys.dm_os_performance_counters
--WHERE [object_name] LIKE '%Buffer Manager%'
--AND [counter_name] = 'Page life expectancy'

SELECT 
 ple.[Node] 
,LTRIM(STR([PageLife_S]/3600))+':'+REPLACE(STR([PageLife_S]%3600/60,2),SPACE(1),'0')+':'+REPLACE(STR([PageLife_S]%60,2),SPACE(1),'0') [PageLife] 
,ple.[PageLife_S] 
,dp.[DatabasePages] [BufferPool_Pages] 
,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125) [BufferPool_MiB] 
,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125/[PageLife_S]) [BufferPool_MiB_S] 
FROM 
( 
SELECT [instance_name] [node],[cntr_value] [PageLife_S] FROM sys.dm_os_performance_counters 
WHERE [counter_name] = 'Page life expectancy' 
) ple 
INNER JOIN 
( 
SELECT [instance_name] [node],[cntr_value] [DatabasePages] FROM sys.dm_os_performance_counters 
WHERE [counter_name] = 'Database pages' 
) dp ON ple.[node] = dp.[node]
