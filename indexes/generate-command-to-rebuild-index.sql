/**
	Generate rebuild/reorganize index commands to a especific database
*/
DECLARE @Id_Database INT = db_id()
DECLARE @Table_ID INT

IF object_id('tempdb..#Historico_Fragmentacao_Indice_TEMP') IS NOT NULL DROP TABLE #Historico_Fragmentacao_Indice_TEMP
CREATE TABLE #Historico_Fragmentacao_Indice_TEMP(
	[Dt_Referencia] [datetime] NULL,
	[Nm_Servidor] VARCHAR(50) NULL,
	[Nm_Database] VARCHAR(100) NULL,
	[Nm_Tabela] VARCHAR(1000) NULL,
	[Nm_Indice] [varchar](1000) NULL,
	[Nm_Schema] varchar(100),
	[avg_fragmentation_in_percent] [numeric](5, 2) NULL,
	[page_count] [int] NULL,
	[fill_factor] [tinyint] NULL,
	[Fl_Compressao] [tinyint] NULL,
	[ObjectID] int,
	[indexid] int
) ON [PRIMARY]

IF object_id('tempdb..#Historico_Fragmentacao_Indice') IS NOT NULL DROP TABLE #Historico_Fragmentacao_Indice
CREATE TABLE #Historico_Fragmentacao_Indice(
	[Dt_Referencia] [datetime] NULL,
	[Nm_Servidor] VARCHAR(50) NULL,
	[Nm_Database] VARCHAR(100) NULL,
	[Nm_Tabela] VARCHAR(1000) NULL,
	[Nm_Indice] [varchar](1000) NULL,
	Nm_Schema varchar(100),
	[Avg_Fragmentation_In_Percent] [numeric](5, 2) NULL,
	[Page_Count] [int] NULL,
	[Fill_Factor] [tinyint] NULL,
	[Fl_Compressao] [tinyint] NULL	
) ON [PRIMARY]

IF (OBJECT_ID('tempdb..#Tabelas') IS NOT NULL) DROP TABLE #Tabelas
SELECT OBJECT_NAME(s.object_id) name, s.object_id
INTO #Tabelas
FROM sys.dm_db_partition_stats s
JOIN sys.tables t ON s.object_id = t.object_id
GROUP BY s.object_id
HAVING SUM(s.used_page_count) > 1000

CREATE CLUSTERED INDEX SK01_#Tabelas ON #Tabelas(object_id)

WHILE EXISTS ( SELECT TOP 1 object_id FROM #Tabelas )
BEGIN

	SELECT TOP 1 @Table_ID = object_id FROM #Tabelas
		
	INSERT INTO #Historico_Fragmentacao_Indice_TEMP
	SELECT	GETDATE(),
			@@SERVERNAME Nm_Servidor,
			DB_NAME(@Id_Database) Nm_Database,
			'' Nm_Tabela, B.name Nm_Indice,
			'' Nm_Schema,
			avg_fragmentation_in_percent,
			page_count,
			fill_factor,
			'' data_compression,
			A.object_id,
			A.index_id
	FROM sys.dm_db_index_physical_stats(@Id_Database, @Table_ID, null,null,null) A
	JOIN sys.indexes B ON A.object_id = B.object_id and A.index_id = B.index_id
	--WHERE page_count > 1000

	DELETE TOP(1) FROM #Tabelas WHERE object_id = @Table_ID

END
	
INSERT INTO #Historico_Fragmentacao_Indice
SELECT	A.Dt_Referencia, A.Nm_Servidor,  A.Nm_Database, D.name , A.Nm_Indice, F.name, A.avg_fragmentation_in_percent, A.page_count,A.fill_factor, data_compression
FROM #Historico_Fragmentacao_Indice_TEMP A
JOIN sys.partitions C ON C.object_id = A.ObjectID AND C.index_id = A.indexid
JOIN sys.sysobjects D ON A.ObjectID = D.id
JOIN sys.objects E ON D.id = E.object_id
JOIN  sys.schemas F ON E.schema_id = F.schema_id	
	
IF OBJECT_ID('tempdb..#Indices_Fragmentados' ) IS NOT NULL DROP TABLE #Indices_Fragmentados
SELECT IDENTITY(INT,1,1) Id,Nm_Tabela, 
				CASE WHEN Nm_Indice IS null 
						THEN
							'ALTER TABLE ' + Nm_Schema+'.['+ Nm_Tabela + '] REBUILD'
						ELSE
							'ALTER INDEX ['+ Nm_Indice+ '] ON ' + Nm_Schema+'.['+ Nm_Tabela + 
								CASE when Avg_Fragmentation_In_Percent < 30 then '] REORGANIZE' else '] REBUILD with (PAD_INDEX = on,FILLFACTOR =80,SORT_IN_TEMPDB =on, ONLINE =on)' end
				END Comando,Page_Count,avg_fragmentation_in_percent
INTO #Indices_Fragmentados			
FROM #Historico_Fragmentacao_Indice A WITH(NOLOCK)
WHERE Dt_Referencia >= CAST(FLOOR(cast(getdate() AS FLOAT)) AS DATETIME)
	and ((Avg_Fragmentation_In_Percent >= 10 AND Nm_Indice IS NOT NULL ) OR (Nm_Indice IS null  AND  avg_fragmentation_in_percent > 30))
	--and Page_Count > 1000
	--and Page_Count < 1000000  --indices grandes planejar janela para execução. Ou se quiser libere comentando essa linha
ORDER BY Nm_Indice
		
SELECT * FROM #Indices_Fragmentados
ORDER BY page_count DESC

GO