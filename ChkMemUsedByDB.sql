-- Note: querying sys.dm_os_buffer_descriptors
-- requires the VIEW_SERVER_STATE permission.

DECLARE @total_buffer INT;

SELECT @total_buffer = cntr_value
   FROM sys.dm_os_performance_counters
   WHERE RTRIM([object_name]) LIKE '%Buffer Manager'
   AND counter_name = 'Total Pages';

;WITH src AS
(
   SELECT
       database_id, db_buffer_pages = COUNT_BIG(*)
       FROM sys.dm_os_buffer_descriptors
       --WHERE database_id BETWEEN 5 AND 32766
       GROUP BY database_id
)
SELECT
   [db_name] = CASE [database_id] WHEN 32767
       THEN 'Resource DB'
       ELSE DB_NAME([database_id]) END,
   db_buffer_pages,
   db_buffer_MB = db_buffer_pages / 128,
   db_buffer_percent = CONVERT(DECIMAL(6,3),
       db_buffer_pages * 100.0 / @total_buffer)
FROM src
ORDER BY db_buffer_MB DESC; 


-- does not work!!!
--SELECT 
--* 
--FROM sys.dm_os_memory_clerks 
--ORDER BY (single_pages_kb + multi_pages_kb + awe_allocated_kb) desc



--find out how big buffer pool is and determine percentage used by each database

DECLARE @total_buffer INT;
SELECT @total_buffer = cntr_value   FROM sys.dm_os_performance_counters
WHERE RTRIM([object_name]) LIKE '%Buffer Manager'   AND counter_name = 'Total Pages';
;WITH src AS(   SELECT        database_id, db_buffer_pages = COUNT_BIG(*) 
FROM sys.dm_os_buffer_descriptors       --WHERE database_id BETWEEN 5 AND 32766       
GROUP BY database_id)SELECT   [db_name] = CASE [database_id] WHEN 32767        THEN 'Resource DB'        ELSE DB_NAME([database_id]) END,   db_buffer_pages,   db_buffer_MB = db_buffer_pages / 128,   db_buffer_percent = CONVERT(DECIMAL(6,3),        db_buffer_pages * 100.0 / @total_buffer)
FROM src
ORDER BY db_buffer_MB DESC;

--then drill down into memory used by objects in database of your choice

USE <DB_Name_Here> --db_with_most_memory;
go
;WITH src AS(   SELECT       [Object] = o.name,       [Type] = o.type_desc,       [Index] = COALESCE(i.name, ''),       [Index_Type] = i.type_desc,       p.[object_id],       p.index_id,       au.allocation_unit_id   
FROM       sys.partitions AS p   INNER JOIN       sys.allocation_units AS au       ON p.hobt_id = au.container_id   INNER JOIN       sys.objects AS o       ON p.[object_id] = o.[object_id]   INNER JOIN       sys.indexes AS i       ON o.[object_id] = i.[object_id]       AND p.index_id = i.index_id   WHERE       au.[type] IN (1,2,3)       AND o.is_ms_shipped = 0)
SELECT   src.[Object],   src.[Type],   src.[Index],   src.Index_Type,   buffer_pages = COUNT_BIG(b.page_id),   buffer_mb = COUNT_BIG(b.page_id) / 128
FROM   src
INNER JOIN   sys.dm_os_buffer_descriptors AS b  
 ON src.allocation_unit_id = b.allocation_unit_id
WHERE   b.database_id = DB_ID()
GROUP BY   src.[Object],   src.[Type],   src.[Index],   src.Index_Type
ORDER BY   buffer_pages DESC;



-- Top Cached SPs By Total Logical Reads (SQL 2008). Logical reads relate to memory pressure
SELECT TOP(25) p.name AS [SP Name], qs.total_logical_reads AS [TotalLogicalReads],
qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count
AS [avg_elapsed_time], qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC;

-- This helps you find the most expensive cached stored procedures from a memory perspective
-- You should look at this if you see signs of memory pressure
