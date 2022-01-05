/*
	Reference: https://www.scarydba.com/2021/06/14/find-queries-using-a-key-lookup-operator/
*/
DECLARE @DatabaseName VARCHAR(40) = 'DatabaseName'
DECLARE @TableName VARCHAR(40) = 'Tablename'

SELECT TOP 10
		DB_NAME(detqp.dbid),
		dest.text,
		SUBSTRING(   dest.text,
                    (deqs.statement_start_offset / 2) + 1,
                    (CASE deqs.statement_end_offset
                         WHEN -1 THEN
                             DATALENGTH(dest.text)
                         ELSE
                             deqs.statement_end_offset
                     END - deqs.statement_start_offset
                    ) / 2 + 1
                ) AS StatementText,
		CAST(detqp.query_plan AS XML),
		deqs.execution_count,
		deqs.total_elapsed_time,
		deqs.total_logical_reads,
		deqs.total_logical_writes
FROM sys.dm_exec_query_stats AS deqs
    CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle, deqs.statement_start_offset, deqs.statement_end_offset) AS detqp
    CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
WHERE	detqp.query_plan LIKE '%Lookup="1"%' AND
		DB_NAME(detqp.dbid) = @DatabaseName AND
		dest.text LIKE '%' + @TableName + '%'

GO