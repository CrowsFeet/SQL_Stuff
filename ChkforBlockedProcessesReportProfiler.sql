-- you need to enable this for the profiler to be able to use the deadlock trace options
USE master
GO

SP_CONFIGURE'show advanced options',1 ;
GO
RECONFIGURE
;
GO

SP_CONFIGURE'blocked process threshold',10 ;
GO
RECONFIGURE
;
GO

SP_CONFIGURE'blocked process threshold',0 ;

GO

RECONFIGURE

;

GO