-- you need to enable this for the profiler to be able to use the deadlock trace options

-- with the improvements to Extended Events, profiler is on it way out. shame as I still dont like EE.
-- however, if you are trying to get Profiler to report on deadlocks, then you need to enable the following and set it to
-- report by a specific time frame.


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
