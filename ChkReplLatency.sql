USE HostedMaintenance
go

-- Check Latency
---------------------------------------------------------------------------
--Define monitoring threshold in the scale of minutes
---------------------------------------------------------------------------

declare @minutes int, @threshold int
set @minutes = 30 --> Here is where you define how many minutes latency you would like to be notified
set @threshold = @minutes * 60 * 1000 
---------------------------------------------------------------------------
--Specify email distribution list, To and CC
---------------------------------------------------------------------------
declare @Tolist varchar(100)
set @Tolist = 'agazdowicz@ecisolutions.com'

declare @CClist varchar(100)
set @CClist = ''

---------------------------------------------------------------------------------------------
--Specify the email subject, @@servername will pick up replication distributor server name
---------------------------------------------------------------------------------------------
declare @mailsubject  varchar(100)
set @mailsubject = @@SERVERNAME + ' Replication Latency'

--select datename(hh,GETDATE())

if exists (
select top 1 1  from sys.dm_os_performance_counters where object_name like '%Replica%'
and counter_name like '%Logreader:%latency%' and cntr_value > @threshold
union
select top 1 1  from sys.dm_os_performance_counters where object_name like '%Replica%'
and counter_name like '%Dist%latency%' and cntr_value > @threshold)
begin

DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>'+@@SERVERNAME+' Replication Latency</H1>' +
    N'<table border="1">' +
    N'<tr><th>Object Name</th><th>Counter Name</th>' +
    N'<th>Instance Name</th><th>latency in sec</th>' +
    CAST ( ( SELECT td = object_name,       '',
                    td = counter_name, '',
                    td = instance_name, '',
                    td = latency_sec, ''
             FROM
             (select object_name, counter_name, instance_name, round(cntr_value/1000,0) as latency_sec from sys.dm_os_performance_counters where object_name like '%Replica%'
                and counter_name like '%Logreader:%latency%' and cntr_value > @threshold
        union
          select object_name, counter_name, instance_name, round(cntr_value/1000,0) as latency_sec from sys.dm_os_performance_counters where object_name like '%Replica%'
                and counter_name like '%Dist%latency%' and cntr_value > @threshold) a
              FOR XML PATH('tr'), TYPE
    ) AS NVARCHAR(MAX) ) +
    N'</table>' ;


SELECT @tableHTML
        --exec  msdb.dbo.sp_send_dbmail
        --@recipients= @Tolist,
        --@copy_recipients = @CClist,
        --@subject = @mailsubject ,
        --@body_format ='HTML',
        --@body = @tableHTML

END