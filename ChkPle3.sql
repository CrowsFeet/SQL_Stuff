
-- ple_per_4gb of every NUMA node should be > 300 sec !
SELECT numa_node = ISNULL(NULLIF(ple.instance_name, ''), 'ALL'), 
    ple_sec = ple.cntr_value, db_node_mem_GB = dnm.cntr_value*8/1048576,
    ple_per_4gb = ple.cntr_value * 4194304 / (dnm.cntr_value*8)
FROM sys.dm_os_performance_counters ple join sys.dm_os_performance_counters dnm
    on ple.instance_name = dnm.instance_name
    and ple.counter_name='Page life expectancy' -- PLE per NUMA node
    and dnm.counter_name='Database pages' -- buffer pool size (pages) per NUMA node