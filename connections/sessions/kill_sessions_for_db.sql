/**
    Obtém todas as sessions de uma determinada DB
    Reference: https://stackoverflow.com/questions/7197574/script-to-kill-all-connections-to-a-database-more-than-restricted-user-rollback
*/



-- IaaS
USE [master];

DECLARE @kill varchar(8000) = '';  
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('databaseName')

EXEC(@kill);



-- PaaS
USE [databaseName]
GO

SELECT *
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('sqldb-voa-dev')

KILL <put the session_id here>