-- Worst performing CPU bound queries
SELECT TOP 5
	st.text,
	qp.query_plan,
	qs.*
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_worker_time DESC
GO

-- Most expensive Queries
SELECT TOP 25
	databases.name,
	dm_exec_sql_text.text AS TSQL_Text,
	CAST(CAST(dm_exec_query_stats.total_worker_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as cpu_per_execution,
	CAST(CAST(dm_exec_query_stats.total_logical_reads AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as logical_reads_per_execution,
	CAST(CAST(dm_exec_query_stats.total_elapsed_time AS DECIMAL)/CAST(dm_exec_query_stats.execution_count AS DECIMAL) AS INT) as elapsed_time_per_execution,
	dm_exec_query_stats.creation_time, 
	dm_exec_query_stats.execution_count,
	dm_exec_query_stats.total_worker_time AS total_cpu_time,
	dm_exec_query_stats.max_worker_time AS max_cpu_time, 
	dm_exec_query_stats.total_elapsed_time, 
	dm_exec_query_stats.max_elapsed_time, 
	dm_exec_query_stats.total_logical_reads, 
	dm_exec_query_stats.max_logical_reads,
	dm_exec_query_stats.total_physical_reads, 
	dm_exec_query_stats.max_physical_reads,
	dm_exec_query_plan.query_plan,
	dm_exec_cached_plans.cacheobjtype,
	dm_exec_cached_plans.objtype,
	dm_exec_cached_plans.size_in_bytes
FROM sys.dm_exec_query_stats 
CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
INNER JOIN sys.databases
ON dm_exec_sql_text.dbid = databases.database_id
INNER JOIN sys.dm_exec_cached_plans 
ON dm_exec_cached_plans.plan_handle = dm_exec_query_stats.plan_handle
WHERE databases.name = 'HZN_QUALITY'