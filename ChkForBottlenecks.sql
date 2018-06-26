-- Lots of little good ones here
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage,
   migs.last_user_seek,
   mid.statement AS 'Database.Schema.Table',
   mid.equality_columns,
   mid.inequality_columns,
   mid.included_columns,
   migs.unique_compiles,
   migs.user_seeks,
   migs.avg_total_user_cost,
   migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK) 
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK) 
    ON mig.index_handle = mid.index_handle
ORDER BY index_advantage DESC;

-- i/o
select *
from sys.dm_os_wait_stats  
where wait_type like 'PAGEIOLATCH%'
order by wait_type ASC

-- disks
select database_id, 
       file_id, 
       io_stall,
       io_pending_ms_ticks,
       scheduler_address 
from sys.dm_io_virtual_file_stats(NULL, NULL) iovfs,
     sys.dm_io_pending_io_requests as iopior
where iovfs.file_handle = iopior.io_handle

-- cpu
select * from sys.dm_os_performance_counters
where counter_name in ('Batch Requests/sec', 'SQL Compilations/sec' , 'SQL Re-Compilations/sec')

/*
The Batch Requests/sec value depends on hardware used, but it should be under 1000. 
The recommended value for SQL Compilations/sec is less than 10% of Batch Requests/sec 
and for SQL Re-Compilations/sec is less than 10% of SQL Compilations/sec
*/
DECLARE @BatchRequests BIGINT;
 
SELECT @BatchRequests = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Batch Requests/sec';
 
WAITFOR DELAY '00:00:10';
 
SELECT (cntr_value - @BatchRequests) / 10 AS 'Batch Requests/sec'
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Batch Requests/sec';
