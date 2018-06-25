use HostedMaintenance
go

---------------------------------------------------------------------------
--How much time you want to trace back on agent failure
--Below example, I am tracing back job failure for current day and past 30 min
---------------------------------------------------------------------------
declare @time time
set @time = dateadd(n,-30,getdate())  -- Here I am setting to trace back only past 30 minutes

declare @date date
set @date = convert(date,getdate())   -- The job failure trace back is defined on current day

---------------------------------------------------------------------------
--Specify the publisher SQL instance name
---------------------------------------------------------------------------
declare @publisher varchar(100)        --
set @publisher = 'ECIC-SQL07'

---------------------------------------------------------------------------
--Specify email distribution list, To and CC
---------------------------------------------------------------------------
declare @Tolist varchar(100)
set @Tolist = 'agazdowicz@ecisolutions.com'

declare @CClist varchar(100)
set @CClist = ''


--select distinct b.name,a.run_date, right('00000'+convert(varchar,a.run_time),6),message 
--from msdb..sysjobhistory a 
--inner join msdb..sysjobs b on a.job_id = b.job_id
--where b.name like @publisher+'%' and run_status <> 1 and message like '%error%'
--and convert(date,convert(varchar,a.run_date ))= @date
--and right('00000'+convert(varchar,a.run_time),6)  > replace(convert(varchar(8),@time),':','')




---------------------------------------------------------------------------------------------
--Specify the email subject, @@servername will pick up replication distributor server name
---------------------------------------------------------------------------------------------
declare @mailsubject  varchar(100)
set @mailsubject = @@SERVERNAME + ' Replication failure'

if exists (
select distinct b.name,a.run_date, right('00000'+convert(varchar,a.run_time),6),message from msdb..sysjobhistory a inner join msdb..sysjobs b on a.job_id = b.job_id
where b.name like @publisher+'%' and run_status <> 1 and message like '%error%'
and convert(date,convert(varchar,a.run_date ))= @date
and right('00000'+convert(varchar,a.run_time),6)  > replace(convert(varchar(8),@time),':','')
)
begin

DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>'+@@SERVERNAME+' Replication Agent Failed</H1>' +
    N'<table border="1">' +
    N'<tr><th>Job Name</th><th>Run Date</th>' +
    N'<th>Run Time</th><th>Failure Message</th>' +
    CAST ( ( SELECT td = name,       '',
                    td = run_date, '',
                    td = run_time, '',
                    td = message, ''
             FROM
             (select name, MAX(run_date) as run_date, MAX(run_time) as run_time, message from
                (select distinct b.name,a.run_date, run_time = right('00000'+convert(varchar,a.run_time),6),message from msdb..sysjobhistory a inner join msdb..sysjobs b on a.job_id = b.job_id
                where b.name like @publisher+'%' and run_status <> 1 and message like '%error%'
                and convert(date,convert(varchar,a.run_date ))= @date
                and right('00000'+convert(varchar,a.run_time),6)  > replace(convert(varchar(8),@time),':','') ) a
                group by name, message
                ) a
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

end