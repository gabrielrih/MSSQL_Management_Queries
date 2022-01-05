/*
	Queries que mais utilizaram CPU
*/
IF object_id('tempdb..#Temp_Trace') IS NOT NULL DROP TABLE #Temp_Trace

SELECT TOP 50 total_worker_time, SQL_HANDLE, execution_count, last_execution_time, last_worker_time
INTO #Temp_Trace
FROM sys.dm_exec_query_stats A
--where last_elapsed_time > 20
	--and last_execution_time > dateadd(ss,-600,getdate()) --ultimos 5 min
ORDER BY A.total_worker_time DESC

SELECT DISTINCT *
FROM #Temp_Trace A
CROSS APPLY sys.dm_exec_sql_text (SQL_HANDLE)
ORDER BY 1 DESC
GO