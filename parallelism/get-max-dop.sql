SELECT [value] as CurrentMAXDOP
FROM sys.database_scoped_configurations 
WHERE [name] = 'MAXDOP';