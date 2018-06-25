;WITH XMLNAMESPACES 
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT --TOP 10
CompileTime_ms,
CompileCPU_ms,
CompileMemory_KB,
qs.execution_count,
qs.total_elapsed_time/1000 AS duration_ms,
qs.total_worker_time/1000 as cputime_ms,
(qs.total_elapsed_time/qs.execution_count)/1000 AS avg_duration_ms,
(qs.total_worker_time/qs.execution_count)/1000 AS avg_cputime_ms,
qs.max_elapsed_time/1000 AS max_duration_ms,
qs.max_worker_time/1000 AS max_cputime_ms,
SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1,
(CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(st.text)
ELSE qs.statement_end_offset
END - qs.statement_start_offset) / 2 + 1) AS StmtText,
query_hash,
query_plan_hash
FROM
(
SELECT 
c.value('xs:hexBinary(substring((@QueryHash)[1],3))', 'varbinary(max)') AS QueryHash,
c.value('xs:hexBinary(substring((@QueryPlanHash)[1],3))', 'varbinary(max)') AS QueryPlanHash,
c.value('(QueryPlan/@CompileTime)[1]', 'int') AS CompileTime_ms,
c.value('(QueryPlan/@CompileCPU)[1]', 'int') AS CompileCPU_ms,
c.value('(QueryPlan/@CompileMemory)[1]', 'int') AS CompileMemory_KB,
qp.query_plan
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY qp.query_plan.nodes('ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS n(c)
) AS tab
JOIN sys.dm_exec_query_stats AS qs
ON tab.QueryHash = qs.query_hash
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY CompileTime_ms DESC
--OPTION(RECOMPILE, MAXDOP 1);


SELECT cache_address, name, [type]
FROM sys.dm_os_memory_cache_counters 
WHERE [type] LIKE 'CACHE%'

USE prod_eo_eo0
go
-- check for single and multi use plans
DECLARE @singleUse FLOAT, @multiUse FLOAT, @total FLOAT
SET @singleUse = ( SELECT COUNT(*) 
     FROM sys.dm_exec_cached_plans 
     WHERE cacheobjtype = 'Compiled Plan' 
     AND usecounts = 1)
SET @multiUse =  ( SELECT COUNT(*) 
     FROM sys.dm_exec_cached_plans 
     WHERE cacheobjtype = 'Compiled Plan' 
     AND usecounts > 1)
SET @total = @singleUse + @multiUse
SELECT 'Single Usecount', ROUND((@singleUse / @total) * 100,2) [pc_single_usecount]
UNION ALL
SELECT 'Multiple Usecount', ROUND((@multiUse / @total) * 100,2) 


-- now we check for offending plans
SELECT TOP 100 t.[text] 
FROM sys.dm_exec_cached_plans p
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) t
WHERE usecounts = 1
AND  cacheobjtype = 'Compiled Plan'
AND  objtype = 'Adhoc'
AND  t.[text] NOT LIKE '%SELECT%TOP%10%t%text%'


SELECT
sst.name AS [Schema],
st.name AS [Name]
FROM
sys.types AS st
INNER JOIN sys.schemas AS sst ON sst.schema_id = st.schema_id
WHERE
(st.schema_id!=4 and st.system_type_id!=240 
and st.user_type_id != st.system_type_id and st.is_table_type != 1)
ORDER BY
[Schema] ASC,[Name] ASC


