-- This script will list all Table statistics and when they were last updated.
SELECT 
	obj.name
	,obj.object_id
	,stat.name
	,stat.stats_id
	,last_updated, 
	modification_counter  
FROM sys.objects AS obj   
	INNER JOIN sys.stats AS stat ON stat.object_id = obj.object_id  
	CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp  
WHERE modification_counter > 1000;  

--EXEC sp_updatestats;



