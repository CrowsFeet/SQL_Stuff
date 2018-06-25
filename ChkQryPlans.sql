USE master
go
SELECT
t1.resource_type,
t1.resource_database_id,
t1.resource_associated_entity_id,
t1.request_mode,
t1.request_session_id,
t2.blocking_session_id,
o1.name 'object name',
o1.type_desc 'object descr',
p1.partition_id 'partition id',
p1.rows 'partition/page rows',
a1.type_desc 'index descr',
a1.container_id 'index/page container_id'
FROM sys.dm_tran_locks as t1
INNER JOIN sys.dm_os_waiting_tasks as t2
	ON t1.lock_owner_address = t2.resource_address
LEFT OUTER JOIN sys.objects o1 on o1.object_id = t1.resource_associated_entity_id
LEFT OUTER JOIN sys.partitions p1 on p1.hobt_id = t1.resource_associated_entity_id
LEFT OUTER JOIN sys.allocation_units a1 on a1.allocation_unit_id = t1.resource_associated_entity_id

-------------------

USE <DBName_Here>
go
SELECT  deqs.plan_handle ,
        deqs.sql_handle ,
        execText.text
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE   execText.text LIKE 'CREATE PROCEDURE ShowQueryText%'

------------------


SELECT  deqp.dbid ,
        deqp.objectid ,
        CAST(detqp.query_plan AS XML) AS singleStatementPlan ,
        deqp.query_plan AS batch_query_plan ,
        --this won't actually work in all cases because nominal plans aren't
        -- cached, so you won't see a plan for waitfor if you uncomment it
        ROW_NUMBER() OVER ( ORDER BY Statement_Start_offset )
                                               AS query_position ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle,
                                                deqs.statement_start_offset,
                                                deqs.statement_end_offset)
                                                                    AS detqp
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE   deqp.objectid = OBJECT_ID('ShowQueryText', 'p') ;

------------



SELECT  COUNT(*)
FROM    sys.dm_exec_cached_plans ;

---


SELECT  MAX(CASE WHEN usecounts BETWEEN 10 AND 100 THEN '10-100'
                 WHEN usecounts BETWEEN 101 AND 1000 THEN '101-1000'
                 WHEN usecounts BETWEEN 1001 AND 5000 THEN '1001-5000'
                 WHEN usecounts BETWEEN 5001 AND 10000 THEN '5001-10000'
                 ELSE CAST(usecounts AS VARCHAR(100))
            END) AS usecounts ,
        COUNT(*) AS countInstance
FROM    sys.dm_exec_cached_plans
GROUP BY CASE WHEN usecounts BETWEEN 10 AND 100 THEN 50
              WHEN usecounts BETWEEN 101 AND 1000 THEN 500
              WHEN usecounts BETWEEN 1001 AND 5000 THEN 2500
              WHEN usecounts BETWEEN 5001 AND 10000 THEN 7500
              ELSE usecounts
         END
ORDER BY CASE WHEN usecounts BETWEEN 10 AND 100 THEN 50
              WHEN usecounts BETWEEN 101 AND 1000 THEN 500
              WHEN usecounts BETWEEN 1001 AND 5000 THEN 2500
              WHEN usecounts BETWEEN 5001 AND 10000 THEN 7500
              ELSE usecounts
         END DESC ;


---------------------------

SELECT TOP 5 WITH TIES
        decp.usecounts ,
        decp.cacheobjtype ,
        decp.objtype ,
        deqp.query_plan ,
        dest.text
FROM    sys.dm_exec_cached_plans decp
        CROSS APPLY sys.dm_exec_query_plan(decp.plan_handle) AS deqp
        CROSS APPLY sys.dm_exec_sql_text(decp.plan_handle) AS dest
ORDER BY usecounts DESC ;

------------------

-- single use plans


-- Find single-use, ad hoc queries that are bloating the plan cache

SELECT TOP ( 100 )
        [text] ,
        cp.size_in_bytes
FROM    sys.dm_exec_cached_plans AS cp
        CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE   cp.cacheobjtype = 'Compiled Plan'
        AND cp.objtype = 'Adhoc'
        AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC ;

---------------------------------------
-- query called on server
SELECT TOP 10
        total_worker_time ,
        execution_count ,
        total_worker_time / execution_count AS [Avg CPU Time] ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
ORDER BY deqs.total_worker_time DESC ;


-------------------------------------

SELECT TOP 100
        SUM(total_logical_reads) AS total_logical_reads ,
        COUNT(*) AS num_queries , --number of individual queries in batch
        --not all usages need be equivalent, in the case of looping
        --or branching code
        MAX(execution_count) AS execution_count ,
        MAX(execText.text) AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS execText
GROUP BY deqs.sql_handle
HAVING  AVG(total_logical_reads / execution_count) <> SUM(total_logical_reads)
        / SUM(execution_count)
ORDER BY 1 DESC


-------------------------------------------

-- expensive cached SPs



-- Top Cached SPs By Total Logical Reads (SQL 2008 only).

-- Logical reads relate to memory pressure

SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        deps.total_logical_reads AS [TotalLogicalReads] ,
        deps.total_logical_reads / deps.execution_count AS [AvgLogicalReads] ,
        deps.execution_count ,
        ISNULL(deps.execution_count / DATEDIFF(Second, deps.cached_time,
                                           GETDATE()), 0) AS [Calls/Second] ,
        deps.total_elapsed_time ,
        deps.total_elapsed_time / deps.execution_count AS [avg_elapsed_time] ,
        deps.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats
                      AS deps ON p.[object_id] = deps.[object_id]
WHERE   deps.database_id = DB_ID()
ORDER BY deps.total_logical_reads DESC ;


-------------------------------

SELECT  counter ,
        occurrence ,
        value
FROM    sys.dm_exec_query_optimizer_info
WHERE   counter IN ( 'optimizations', 'elapsed time', 'final cost' ) ;
go


SELECT  COUNTER ,
        OCCURRENCE ,
        VALUE
FROM    SYS.DM_EXEC_QUERY_OPTIMIZER_INFO
WHERE   COUNTER IN ( 'optimizations', 'elapsed time', 'final cost' ) ;
