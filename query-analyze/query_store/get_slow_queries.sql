SELECT TOP 50
	stat.plan_id,
	Qry.query_id AS query_id,
	Txt.query_sql_text AS query,
	FORMAT(MIN(stat.first_execution_time), 'yyyy-MM-dd HH:MM:ss') AS first_execution_time,
	FORMAT(MAX(stat.last_execution_time), 'yyyy-MM-dd HH:MM:ss') AS last_execution_time,
	SUM(stat.count_executions) AS count_executions,
	AVG(stat.avg_duration) / 1000 AS avg_duration_in_ms,
	MIN(stat.min_duration) / 1000 AS min_duration_in_ms,
	MAX(stat.max_duration) / 1000 AS max_duration_in_ms,
    AVG(stat.avg_logical_io_reads) AS avg_logical_io_reads,
	AVG(stat.avg_logical_io_writes) AS avg_logical_io_writes,
	AVG(stat.avg_physical_io_reads) AS avg_physical_io_reads,
	AVG(stat.avg_rowcount) AS avg_rowcount
FROM sys.query_store_runtime_stats stat
INNER JOIN sys.query_store_plan AS Pl ON stat.plan_id = Pl.plan_id
INNER JOIN sys.query_store_query AS Qry ON Pl.query_id = Qry.query_id
INNER JOIN sys.query_store_query_text AS Txt ON Qry.query_text_id = Txt.query_text_id
WHERE runtime_stats_interval_id IN (
	SELECT runtime_stats_interval_id FROM sys.query_store_runtime_stats_interval
	WHERE start_time between '2024-04-19T00:00:00.000' AND '2024-04-20T00:00:00.000'
)
and avg_duration > 10000 * 1000 -- in microseconds
GROUP BY stat.plan_id, Qry.query_id, Txt.query_sql_text
ORDER BY count_executions DESC, avg_duration_in_ms DESC
GO
