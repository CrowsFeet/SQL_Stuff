/* -- Get the Instance Name of the Current Connection -- */
DECLARE @instancename AS VARCHAR(20) = (
        SELECT @@SERVICENAME
        )

/* -- Take a 10 second sample of read/write activities -- */
DECLARE @PageReads BIGINT
DECLARE @PageWrites BIGINT
DECLARE @LazyWrites BIGINT

SET @PageReads = (
        SELECT [cntr_value]
        FROM sys.dm_os_performance_counters
        WHERE [object_name] LIKE '%Buffer Manager%'
            AND [counter_name] IN ('Page reads/sec')
        )
--,'Page writes/sec'
--,'Lazy writes/sec'
SET @PageWrites = (
        SELECT [cntr_value]
        FROM sys.dm_os_performance_counters
        WHERE [object_name] LIKE '%Buffer Manager%'
            AND [counter_name] IN (
                --'Page reads/sec'
                'Page writes/sec'
                )
        )
--,'Lazy writes/sec'
SET @LazyWrites = (
        SELECT [cntr_value]
        FROM sys.dm_os_performance_counters
        WHERE [object_name] LIKE '%Buffer Manager%'
            AND [counter_name] IN (
                --'Page reads/sec'
                --'Page writes/sec'
                'Lazy writes/sec'
                )
        )

WAITFOR DELAY '00:00:10'

/* -- Buffer Cache Hit Ratio -- */
--The % of requests that can be satisifed by pages already in the memory buffer.
--The higher the percentage the better the performance and less physical I/0 required.
SELECT 'Buffer cache hit ratio' AS TheCounter
    ,(a.cntr_value * 1.0 / b.cntr_value) * 100.0 AS Value
FROM sys.dm_os_performance_counters a
JOIN (
    SELECT cntr_value
        ,OBJECT_NAME
    FROM sys.dm_os_performance_counters
    WHERE counter_name = 'Buffer cache hit ratio base'
        AND OBJECT_NAME = 'MSSQL$' + @instancename + ':Buffer Manager'
    ) b ON a.OBJECT_NAME = b.OBJECT_NAME
WHERE a.counter_name = 'Buffer cache hit ratio'
    AND a.OBJECT_NAME = 'MSSQL$' + @instancename + ':Buffer Manager'

UNION ALL

/*-- Page Life Expectancy --*/
--The measure, in seconds, of how long a page can remain in the buffer for before it
--is trashed to make room for more pages. A value of lower than 300 is generally seen
--as indicative of poor performance
SELECT counter_name AS TheCounter
    ,cntr_value AS Value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Page life expectancy'
    AND OBJECT_NAME = 'MSSQL$' + @instancename + ':Buffer Manager'

UNION ALL

--Total Server Memory vs. Target Server Memory
--Target Server Memory = The max available to SQL Server
--Total Server Memory = The amount of RAM SQL is actually using
SELECT counter_name AS TheCounter
    ,cntr_value AS Value
FROM sys.dm_os_performance_counters
WHERE counter_name IN (
        'Total Server Memory (KB)'
        ,'Target Server Memory (KB)'
        ,'Stolen Server Memory (KB)'
        )

UNION ALL

--Memory Grants Pending
--Should be <= 1. If higher than 1 it suggests that some operations
--are waiting for memory to come available before SQL Server will allow
--them to proceed.
SELECT 'Memory grants pending' AS TheCounter
    ,[cntr_value] AS Value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Memory Manager%'
    AND [counter_name] = 'Memory Grants Pending'

UNION ALL

SELECT [counter_name] AS TheCounter
    ,CASE 
        WHEN counter_name = 'Page reads/sec'
            THEN ([cntr_value] - @PageReads) / 10
        WHEN counter_name = 'Page writes/sec'
            THEN ([cntr_value] - @PageWrites) / 10
        WHEN counter_name = 'Lazy writes/sec'
            THEN ([cntr_value] - @LazyWrites) / 10
        END AS Value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Buffer Manager%'
    AND [counter_name] IN (
        'Page reads/sec'
        ,'Page writes/sec'
        ,'Lazy writes/sec'
        )