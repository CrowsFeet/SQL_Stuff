SELECT login_time AS 'Started',
DATEDIFF(DAY, login_time, CURRENT_TIMESTAMP) AS 'Uptime in days'
FROM sys.sysprocesses 
WHERE spid = 1;