-- More scripts that will show you how bad/good your system is...


-- Check for tempdb spills. 
-- missing join predicates or columns with no statistics and so on.
DECLARE @database_name NVARCHAR(128) = 'AdventureWorks2014';
;WITH XMLNAMESPACES
    (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')   
SELECT
	dm_exec_sql_text.text AS sql_text,
	CAST(CAST(dm_exec_query_stats.execution_count AS DECIMAL) / CAST((CASE WHEN DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP) = 0 THEN 1 ELSE DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP) END) AS DECIMAL) AS INT) AS executions_per_hour,
	dm_exec_query_stats.creation_time, 
	dm_exec_query_stats.execution_count,
	CAST(CAST(dm_exec_query_stats.total_worker_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as cpu_per_execution,
	CAST(CAST(dm_exec_query_stats.total_logical_reads AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as logical_reads_per_execution,
	CAST(CAST(dm_exec_query_stats.total_elapsed_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as elapsed_time_per_execution,
	dm_exec_query_stats.total_worker_time AS total_cpu_time,
	dm_exec_query_stats.max_worker_time AS max_cpu_time, 
	dm_exec_query_stats.total_elapsed_time, 
	dm_exec_query_stats.max_elapsed_time, 
	dm_exec_query_stats.total_logical_reads, 
	dm_exec_query_stats.max_logical_reads,
	dm_exec_query_stats.total_physical_reads, 
	dm_exec_query_stats.max_physical_reads,
	dm_exec_query_plan.query_plan
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.sql_handle)
CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
WHERE query_plan.exist('//Warnings') = 1
AND query_plan.exist('//ColumnReference[@Database = "[AdventureWorks2014]"]') = 1
ORDER BY dm_exec_query_stats.total_worker_time DESC;



/*
SELECT
	dm_exec_query_plan.query_plan,
	usecounts AS execution_count,
	dm_exec_sql_text.text
FROM sys.dm_exec_cached_plans
CROSS APPLY sys.dm_exec_query_plan(plan_handle)
INNER JOIN sys.dm_exec_query_stats
ON dm_exec_query_stats.plan_handle = dm_exec_cached_plans.plan_handle
CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.plan_handle)
WHERE CAST(dm_exec_query_plan.query_plan AS NVARCHAR(MAX)) LIKE '%Function%' -- looking for an function
--WHERE CAST(dm_exec_query_plan.query_plan AS NVARCHAR(MAX)) LIKE '%PK_SalesOrderHeader_SalesOrderID%' -- looking for an index
 */

 -- looking for queries that generate table scans or clustered index scans
DECLARE @database_name NVARCHAR(128) = 'AdventureWorks2014';
;WITH XMLNAMESPACES
    (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')   
SELECT
	dm_exec_sql_text.text AS sql_text,
	CAST(CAST(dm_exec_query_stats.execution_count AS DECIMAL) / CAST((CASE WHEN DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP) = 0 THEN 1 ELSE DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP) END) AS DECIMAL) AS INT) AS executions_per_hour,
	dm_exec_query_stats.creation_time, 
	dm_exec_query_stats.execution_count,
	CAST(CAST(dm_exec_query_stats.total_worker_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as cpu_per_execution,
	CAST(CAST(dm_exec_query_stats.total_logical_reads AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as logical_reads_per_execution,
	CAST(CAST(dm_exec_query_stats.total_elapsed_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as elapsed_time_per_execution,
	dm_exec_query_stats.total_worker_time AS total_cpu_time,
	dm_exec_query_stats.max_worker_time AS max_cpu_time, 
	dm_exec_query_stats.total_elapsed_time, 
	dm_exec_query_stats.max_elapsed_time, 
	dm_exec_query_stats.total_logical_reads, 
	dm_exec_query_stats.max_logical_reads,
	dm_exec_query_stats.total_physical_reads, 
	dm_exec_query_stats.max_physical_reads,
	dm_exec_query_plan.query_plan
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.sql_handle)
CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
WHERE (query_plan.exist('//RelOp[@PhysicalOp = "Index Scan"]') = 1
	   OR query_plan.exist('//RelOp[@PhysicalOp = "Clustered Index Scan"]') = 1)
AND query_plan.exist('//ColumnReference[@Database = "[AdventureWorks2014]"]') = 1
ORDER BY dm_exec_query_stats.total_worker_time DESC;


-- Large plans in plan cache
SELECT
	dm_exec_sql_text.text,
	dm_exec_cached_plans.objtype,
	dm_exec_cached_plans.size_in_bytes,
	dm_exec_query_plan.query_plan
FROM sys.dm_exec_cached_plans
CROSS APPLY sys.dm_exec_sql_text(dm_exec_cached_plans.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(dm_exec_cached_plans.plan_handle)
WHERE dm_exec_cached_plans.cacheobjtype = N'Compiled Plan'
AND dm_exec_cached_plans.objtype IN(N'Adhoc', N'Prepared')
AND dm_exec_cached_plans.usecounts = 1
ORDER BY dm_exec_cached_plans.size_in_bytes DESC;

-- Get Total cache size
SELECT
	SUM(CAST(dm_exec_cached_plans.size_in_bytes AS BIGINT)) / 1024 AS size_in_KB
FROM sys.dm_exec_cached_plans
WHERE dm_exec_cached_plans.cacheobjtype = N'Compiled Plan'
AND dm_exec_cached_plans.objtype IN(N'Adhoc', N'Prepared')
AND dm_exec_cached_plans.usecounts = 1;

-- average age of execution plan by db
SELECT
	AVG(DATEDIFF(HOUR, dm_exec_query_stats.creation_time, CURRENT_TIMESTAMP)) AS average_create_time
FROM sys.dm_exec_query_stats 
CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
INNER JOIN sys.databases
ON dm_exec_sql_text.dbid = databases.database_id
WHERE databases.name = 'HZN_QUALITY'


-- plan cache usage by db  
SELECT
	databases.name,
	SUM(CAST(dm_exec_cached_plans.size_in_bytes AS BIGINT)) AS plan_cache_size_in_bytes,
	COUNT(*) AS number_of_plans
FROM sys.dm_exec_query_stats query_stats 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS query_plan
INNER JOIN sys.databases
ON databases.database_id = query_plan.dbid
INNER JOIN sys.dm_exec_cached_plans
ON dm_exec_cached_plans.plan_handle = query_stats.plan_handle
GROUP BY databases.name
 
 
-- number of plans and space used for a specific index
DECLARE @index_name AS NVARCHAR(128) = '[PK_SalesOrderHeader_SalesOrderID]';
 
;WITH XMLNAMESPACES
    (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')   
SELECT
	SUM(CAST(dm_exec_cached_plans.size_in_bytes AS BIGINT)) AS plan_cache_size_in_bytes,
	COUNT(*) AS number_of_plans
FROM sys.dm_exec_cached_plans
CROSS APPLY sys.dm_exec_query_plan(plan_handle)
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS nodes(stmt)
CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@index_name")]') AS index_object(obj)
 

---- Worst performing CPU bound queries
--SELECT TOP 5
--	st.text
----	,qp.query_plan
----	,qs.*
--FROM sys.dm_exec_query_stats qs
--CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
--CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
--WHERE CHARINDEX('Function',st.text,0)>0
--ORDER BY total_worker_time DESC
--GO

-- Find Specific Object
SELECT TOP 10
		databases.name,
	dm_exec_sql_text.text AS TSQL_Text,
	dm_exec_query_stats.creation_time, 
	dm_exec_query_stats.execution_count,
	dm_exec_query_stats.total_worker_time AS total_cpu_time,
	dm_exec_query_stats.total_elapsed_time, 
	dm_exec_query_stats.total_logical_reads, 
	dm_exec_query_stats.total_physical_reads, 
	dm_exec_query_plan.query_plan
FROM sys.dm_exec_query_stats 
CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
INNER JOIN sys.databases
ON dm_exec_sql_text.dbid = databases.database_id
WHERE dm_exec_sql_text.text LIKE '%function%';
