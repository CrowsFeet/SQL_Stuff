SELECT database_id,name, snapshot_isolation_state_desc 
FROM sys.databases 
WHERE name LIKE '%prod_power%'
ORDER BY name
