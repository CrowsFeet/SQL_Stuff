SELECT database_id,name, snapshot_isolation_state_desc 
FROM sys.databases 
WHERE name LIKE '%<database name here>%'
ORDER BY name
