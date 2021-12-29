/* For all databases */
SELECT * FROM sys.sysprocesses WHERE open_tran = 1
GO

/* For current database */
DBCC OPENTRAN
GO
