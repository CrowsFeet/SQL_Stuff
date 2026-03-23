USE [master]
GO

CREATE SERVER AUDIT login_perm_audit
TO SECURITY_LOG
GO

CREATE SERVER AUDIT [login_perm_audit]
TO APPLICATION_LOG WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE)
ALTER SERVER AUDIT [login_perm_audit] WITH (STATE = ON)
GO


USE [master]
GO

CREATE SERVER AUDIT SPECIFICATION [login_audit_spec]
FOR SERVER AUDIT [login_perm_audit]
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (SERVER_PERMISSION_CHANGE_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = ON)
GO


/*
https://www.npartner.com/download/document/tech-documentation/N-Partner_MS_SQL_Server_EventLog-EN.pdf

auditpol /set /subcategory:"application generated" /success:enable /failure:enable

SELECT *
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_XE_LOG'

ALTER SERVER AUDIT [login_perm_audit] WITH (STATE = OFF)
GO
ALTER SERVER AUDIT [login_perm_audit] WITH (STATE = ON)
GO 



*/
