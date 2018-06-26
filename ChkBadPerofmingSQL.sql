-- I use this script quite a lot to review bad queries.
SELECT TOP 500
  [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count,
  [Total IO] = (total_logical_reads + total_logical_writes),
  [Execution count] = qs.execution_count,
  [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2),
  [Parent Query] = qt.text,
  DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
--WHERE qt.text LIKE '%Return Reason%'
ORDER BY [Average IO] DESC;
