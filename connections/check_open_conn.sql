USE MASTER
GO

-- Agrupa por BD
SELECT a.dbid,b.name, count(a.dbid) AS TotalConnections
FROM sys.sysprocesses a
INNER JOIN sys.databases b ON a.dbid = b.database_id
GROUP BY a.dbid, b.name
ORDER BY TotalConnections DESC
GO

-- Agrupa por hostname
SELECT a.dbid, b.name, a.hostname, count(a.dbid) AS TotalConnections
FROM sys.sysprocesses a
INNER JOIN sys.databases b ON a.dbid = b.database_id
GROUP BY a.dbid, b.name, a.hostname
ORDER BY TotalConnections DESC
GO

-- Agrupar por usuário
SELECT 
    login_name AS UserName,
    COUNT(session_id) AS TotalConnections
FROM 
    sys.dm_exec_sessions
WHERE 
    is_user_process = 1 -- Filters out system sessions
GROUP BY 
    login_name
ORDER BY 
    login_name
GO
