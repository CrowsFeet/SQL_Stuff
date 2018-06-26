-- a few SQL commands for reviewing SQL Cache.
-- The following example returns the SQL text of all cached entries that have been used more than once.
SELECT usecounts, cacheobjtype, objtype, text 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE usecounts > 1 
ORDER BY usecounts DESC;
GO

-- The following example returns the query plans of all cached triggers.
SELECT plan_handle, query_plan, objtype 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) 
WHERE objtype ='Trigger';
GO

-- The following example returns the SET options with which the plan was compiled. The sql_handle for the plan is also returned. The PIVOT operator is used to output the set_options and sql_handle attributes as columns rather than as rows. For more information about the value returned in set_options,
SELECT plan_handle, pvt.set_options, pvt.sql_handle
FROM (
      SELECT plan_handle, epa.attribute, epa.value 
      FROM sys.dm_exec_cached_plans 
      OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
      WHERE cacheobjtype = 'Compiled Plan'
      ) AS ecpa 
PIVOT (MAX(ecpa.value) FOR ecpa.attribute IN ("set_options", "sql_handle")) AS pvt;
GO

-- The following example returns a breakdown of the memory used by all compiled plans in the cache.
SELECT plan_handle, ecp.memory_object_address AS CompiledPlan_MemoryObject, 
    omo.memory_object_address, pages_in_bytes, type, page_size_in_bytes 
FROM sys.dm_exec_cached_plans AS ecp 
JOIN sys.dm_os_memory_objects AS omo 
    ON ecp.memory_object_address = omo.memory_object_address 
    OR ecp.memory_object_address = omo.parent_address
WHERE cacheobjtype = 'Compiled Plan';
GO


------------------------------------------------------
-- http://dba.stackexchange.com/questions/74091/optimize-for-ad-hoc-workload
-- really good one this one.
SELECT objtype AS [CacheType]
    ,count_big(*) AS [Total Plans]
    ,sum(cast(size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs]
    ,avg(usecounts) AS [Avg Use Count]
    ,sum(cast((
                CASE 
                    WHEN usecounts = 1
                        THEN size_in_bytes
                    ELSE 0
                    END
                ) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs - USE Count 1]
    ,sum(CASE 
            WHEN usecounts = 1
                THEN 1
            ELSE 0
            END) AS [Total Plans - USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs - USE Count 1] DESC

------------------------------------------------------------------------------------

SELECT objtype AS [CacheType]
        , count_big(*) AS [Total Plans]
        , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
        , avg(usecounts) AS [Avg Use Count]
        , sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs – USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans – USE Count 1]
FROM sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs – USE Count 1] DESC
GO 

--------------------------------------------------------------------------------------

SELECT * FROM sys.dm_exec_cached_plans
WHERE cacheobjtype LIKE 'Compiled Plan%'

SELECT * FROM sys.dm_exec_cached_plans
WHERE objtype LIKE '%Adhoc%'

