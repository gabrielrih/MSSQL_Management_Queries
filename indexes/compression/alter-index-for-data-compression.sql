/*
	Compressão a nivel de página.
	Usa menos espaço em disco e na RAM.
	Compacta mais e usa mais CPU para recuperar o dado (SELECT).
*/
ALTER INDEX NOME_INDICE ON NOME_TABELA REBUILD
WITH(DATA_COMPRESSION=PAGE)
GO

/*
	Compressão a nivel de linha.
	Usa menos espaço em disco e na RAM.
	Compacta menos e usa menos CPU para recuperar o dado (SELECT).
*/
ALTER INDEX NOME_INDICE ON NOME_TABELA REBUILD
WITH(DATA_COMPRESSION=ROW)
GO