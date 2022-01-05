/*
	Queries que tiveram mais IO de disco
	(total_physical_reads + total_logical_reads + total_logical_writes)
*/
IF object_id('tempdb..#Temp_Trace') IS NOT NULL DROP TABLE #Temp_Trace

SELECT TOP 50 total_physical_reads + total_logical_reads + total_logical_writes IO, SQL_HANDLE,execution_count,last_execution_time,last_worker_time,total_worker_time
INTO #Temp_Trace
FROM sys.dm_exec_query_stats A
WHERE last_elapsed_time > 20	
ORDER BY A.total_physical_reads + A.total_logical_reads + A.total_logical_writes DESC

SELECT DISTINCT *
FROM #Temp_Trace A
CROSS APPLY sys.dm_exec_sql_text (SQL_HANDLE)
ORDER BY 1 DESC
GO