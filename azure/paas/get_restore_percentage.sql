USE master
GO

SELECT * FROM sys.dm_operation_status 
WHERE operation LIKE '%Restore%' 
ORDER BY Start_Time DESC
GO