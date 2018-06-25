SELECT *
  FROM sys.dm_os_performance_counters
  WHERE counter_name IN('Batch Requests/sec', 'SQL Compilations/sec', 'SQL Re-Compilations/sec')

DECLARE @CountVal BIGINT;
SELECT @CountVal = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'SQL Re-Compilations/sec';
WAITFOR DELAY '00:00:10';
SELECT (cntr_value - @CountVal) / 10 AS 'SQL Re-Compilations/sec'
FROM sys.dm_os_performance_counters
WHERE counter_name = 'SQL Re-Compilations/sec';

SELECT TOP 100
qs.plan_generation_num,
qs.execution_count,
DB_NAME(st.dbid) AS DbName,
st.objectid,
st.TEXT
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
ORDER BY plan_generation_num DESC
