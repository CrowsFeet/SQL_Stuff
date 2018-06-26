-- A long time ago, in a DBA role far far away, I was tasked with a problem a developer was encountering.
-- the problem was a SQL command that they were calling from a front end application, kept stalling or taking several seconds to
-- come back with its results, even though the SQL code ran almost instantly when run from SQL Management Studio (SSMS).
--
-- After a lot of playing about and head scratching and googling (the early days of google), I found an obscure comment from a
-- DBA who had the same issue.
-- turns out that without the arithabout = on, the front end application was not sure if the SQL command had completed or not.

-- This is why I absolutely tell any developer to NEVER write raw t-sql in any front end application. create a stored procedure.
DECLARE @options INT 
SELECT @options = @@OPTIONS 

PRINT @options
IF ( (1 & @options) = 1 ) PRINT 'DISABLE_DEF_CNST_CHK' 
IF ( (2 & @options) = 2 ) PRINT 'IMPLICIT_TRANSACTIONS' 
IF ( (4 & @options) = 4 ) PRINT 'CURSOR_CLOSE_ON_COMMIT' 
IF ( (8 & @options) = 8 ) PRINT 'ANSI_WARNINGS' 
IF ( (16 & @options) = 16 ) PRINT 'ANSI_PADDING' 
IF ( (32 & @options) = 32 ) PRINT 'ANSI_NULLS' 
IF ( (64 & @options) = 64 ) PRINT 'ARITHABORT' 
IF ( (128 & @options) = 128 ) PRINT 'ARITHIGNORE'
IF ( (256 & @options) = 256 ) PRINT 'QUOTED_IDENTIFIER' 
IF ( (512 & @options) = 512 ) PRINT 'NOCOUNT' 
IF ( (1024 & @options) = 1024 ) PRINT 'ANSI_NULL_DFLT_ON' 
IF ( (2048 & @options) = 2048 ) PRINT 'ANSI_NULL_DFLT_OFF' 
IF ( (4096 & @options) = 4096 ) PRINT 'CONCAT_NULL_YIELDS_NULL' 
IF ( (8192 & @options) = 8192 ) PRINT 'NUMERIC_ROUNDABORT' 
IF ( (16384 & @options) = 16384 ) PRINT 'XACT_ABORT'

-- select SESSIONPROPERTY('ARITHABORT')
