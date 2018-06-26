-- Nice little quick check for CPU Usage and Memory Used
DECLARE 
    @cpuUsage float ,   -- % CPU usage
    @memoryUsage float -- % memory usage


    SET NOCOUNT ON;

    /*
     * % CPU usage
     */

    SELECT TOP 1
        @cpuUsage = 100 - r.SystemIdle
    FROM (
        SELECT
            rx.record.value('(./Record/@id)[1]', 'int') AS record_id,
            rx.record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle
        FROM (
            SELECT CONVERT(XML, record) AS record
            FROM sys.dm_os_ring_buffers
            WHERE
                ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' AND
                record LIKE '%<SystemHealth>%') AS rx
        ) AS r
    ORDER BY r.record_id DESC

    /*
     * % memory usage
     */

    SELECT
        @memoryUsage =
            (((m.total_physical_memory_kb - m.available_physical_memory_kb) /
              convert(float, m.total_physical_memory_kb)) *
             100)
 FROM sys.dm_os_sys_memory m

 SELECT @cpuUsage AS CPU_Usage, @memoryUsage AS Memory_Usage

