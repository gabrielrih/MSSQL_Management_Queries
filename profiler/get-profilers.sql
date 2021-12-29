/*
	Retorna os profilers criados no SQL Server
	O TraceId = 1 é o profile padrão do SQL Server.
*/
SELECT * FROM fn_trace_getinfo (NULL)
GO