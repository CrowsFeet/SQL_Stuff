-- SQL Server does store CPU %. however, it only stores the last 24hours and only in 1min intervals.
DECLARE @ts_now BIGINT

select @ts_now = cpu_ticks / (cpu_ticks/ms_ticks) from sys.dm_os_sys_info
     

SELECT  record_id ,
        DATEADD(ms, -1 * ( @ts_now - [timestamp] ), GETDATE()) AS EventTime ,
        SQLProcessUtilization ,
        SystemIdle ,
        100 - SystemIdle - SQLProcessUtilization AS OtherProcessUtilization
FROM    ( SELECT    record.value('(./Record/@id)[1]', 'int') AS record_id ,
                    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]',
                                 'int') AS SystemIdle ,
                    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
                                 'int') AS SQLProcessUtilization ,
                    timestamp
          FROM      ( SELECT    timestamp ,
                                CONVERT(XML, record) AS record
                      FROM      sys.dm_os_ring_buffers
                      WHERE     ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                                AND record LIKE '%<SystemHealth>%'
                    ) AS x
        ) AS y
ORDER BY record_id DESC 
