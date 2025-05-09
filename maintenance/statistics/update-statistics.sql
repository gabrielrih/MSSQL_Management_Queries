/*
	Atualiza as estatísticas a partir de toda a tabela
*/
UPDATE STATISTICS [schema].[table] WITH FULLSCAN
GO

/*
	Atualiza as estatísticas a partir de uma amostra de registros da tabela.
	Não navega em toda a tabela.
*/
UPDATE STATISTICS [schema].[table] WITH SAMPLE
GO
