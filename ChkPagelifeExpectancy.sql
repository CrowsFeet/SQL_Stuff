SELECT [object_name],
[counter_name],
[cntr_value]
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Manager%'
AND [counter_name] = 'Page life expectancy'

-- PLE threshold = ((MAXBP(MB)/1024)/4)*300

-- buffer pool

SELECT
   (CASE WHEN ([is_modified] = 1) THEN N'Dirty' ELSE N'Clean' END) AS N'Page State',
   (CASE WHEN ([database_id] = 32767) THEN N'Resource Database' ELSE DB_NAME ([database_id]) END) AS N'Database Name',
   COUNT (*) AS N'Page Count'
FROM sys.dm_os_buffer_descriptors
   GROUP BY [database_id], [is_modified]
   ORDER BY [database_id], [is_modified];
GO
