SELECT  db.name ,
        m.mirroring_role_desc ,
        mirroring_partner_instance ,
        mirroring_partner_name ,
        mirroring_state_desc ,
		CASE 
			WHEN mirroring_state=0 THEN 'Suspended'
			WHEN mirroring_state=1 THEN 'Disconnected from the other partner'
			WHEN mirroring_state=2 THEN 'Synchronizing'
			WHEN mirroring_state=3 THEN 'Pending Failover'
			WHEN mirroring_state=4 THEN 'Synchronized'
			WHEN mirroring_state=5 THEN 'The partners are not synchronized. Failover is not possible now'
		END AS 'mirroring_state'
--        mirroring_state
FROM    sys.database_mirroring m
        JOIN sys.databases db ON db.database_id = m.database_id
WHERE   mirroring_role_desc = 'PRINCIPAL'
        OR mirroring_role_desc = 'MIRROR'
ORDER BY mirroring_role_desc DESC
GO


SELECT  db.name ,
        mirroring_state
FROM    sys.database_mirroring m
        JOIN sys.databases db ON db.database_id = m.database_id
WHERE   mirroring_role_desc = 'PRINCIPAL'
        OR mirroring_role_desc = 'MIRROR'
ORDER BY mirroring_role_desc DESC
GO

 