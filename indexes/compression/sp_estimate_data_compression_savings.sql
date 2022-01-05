USE DatabaseName
GO

EXEC sp_estimate_data_compression_savings dbo, 'TableOrIndexName', NULL, NULL, 'PAGE' -- ROW
GO