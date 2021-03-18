USE MASTER
SELECT a.dbid,b.name, count(a.dbid) AS TotalConnections
FROM sys.sysprocesses a
INNER JOIN sys.databases b ON a.dbid = b.database_id
GROUP BY a.dbid, b.name