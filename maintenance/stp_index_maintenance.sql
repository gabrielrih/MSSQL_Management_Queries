CREATE PROCEDURE [dbo].[stp_index_maintenance]
AS
BEGIN
    DECLARE @Debug AS BIT = 0
	DECLARE @Fragmentation_To_Reorganize_In_Percent AS INT = 10
	DECLARE @Fragmentation_To_Rebuild_In_Percent AS INT = 30
	DECLARE @Min_Total_Pages AS INT = 1000

SET NOCOUNT ON

IF Object_id('tempdb..#Historico_Fragmentacao_Indice_TEMP') IS NOT NULL
	DROP TABLE #historico_fragmentacao_indice_temp

CREATE TABLE #historico_fragmentacao_indice_temp
(
    [dt_referencia]                [DATETIME] NULL,
    [nm_servidor]                  VARCHAR(50) NULL,
    [nm_database]                  VARCHAR(100) NULL,
    [nm_tabela]                    VARCHAR(1000) NULL,
    [nm_indice]                    [VARCHAR](1000) NULL,
    [nm_schema]                    VARCHAR(100),
    [avg_fragmentation_in_percent] [NUMERIC](5, 2) NULL,
    [page_count]                   [INT] NULL,
    [fill_factor]                  [TINYINT] NULL,
    [fl_compressao]                [TINYINT] NULL,
    [objectid]                     INT,
    [indexid]                      INT
)
ON [PRIMARY]

IF Object_id('tempdb..#Historico_Fragmentacao_Indice') IS NOT NULL
  DROP TABLE #historico_fragmentacao_indice

CREATE TABLE #historico_fragmentacao_indice
(
    [dt_referencia]                [DATETIME] NULL,
    [nm_servidor]                  VARCHAR(50) NULL,
    [nm_database]                  VARCHAR(100) NULL,
    [nm_tabela]                    VARCHAR(1000) NULL,
    [nm_indice]                    [VARCHAR](1000) NULL,
    nm_schema                      VARCHAR(100),
    [avg_fragmentation_in_percent] [NUMERIC](5, 2) NULL,
    [page_count]                   [INT] NULL,
    [fill_factor]                  [TINYINT] NULL,
    [fl_compressao]                [TINYINT] NULL
)
ON [PRIMARY]

DECLARE @Id_Database INT
SET @Id_Database = Db_id()
DECLARE @Table_ID INT

IF ( Object_id('tempdb..#Tabelas') IS NOT NULL )
  DROP TABLE #tabelas

SELECT Object_name(s.object_id) NAME, s.object_id
INTO #tabelas
FROM sys.dm_db_partition_stats s
JOIN sys.tables t ON s.object_id = t.object_id
GROUP  BY s.object_id
HAVING Sum(s.used_page_count) > @Min_Total_Pages

CREATE CLUSTERED INDEX sk01_#tabelas ON #tabelas(object_id)

WHILE EXISTS (SELECT TOP 1 object_id FROM #tabelas)
BEGIN

    SELECT TOP 1 @Table_ID = object_id FROM #tabelas

    INSERT INTO #historico_fragmentacao_indice_temp
    SELECT GETDATE(),
            @@servername          Nm_Servidor,
            Db_name(@Id_Database) Nm_Database,
            ''                    Nm_Tabela,
            B.NAME                Nm_Indice,
            ''                    Nm_Schema,
            avg_fragmentation_in_percent,
            page_count,
            fill_factor,
            ''                    data_compression,
            A.object_id,
            A.index_id
    FROM sys.Dm_db_index_physical_stats(@Id_Database, @Table_ID, NULL, NULL, NULL) A
	JOIN sys.indexes B ON A.object_id = B.object_id AND A.index_id = B.index_id --where page_count > 1000
      
	DELETE #tabelas WHERE  object_id = @Table_ID

END

IF (@Debug = 1)
BEGIN
	SELECT * FROM #historico_fragmentacao_indice_temp
END

INSERT INTO #historico_fragmentacao_indice
SELECT A.dt_referencia,
       A.nm_servidor,
       A.nm_database,
       D.NAME,
       A.nm_indice,
       F.NAME,
       A.avg_fragmentation_in_percent,
       A.page_count,
       A.fill_factor,
       data_compression
FROM   #historico_fragmentacao_indice_temp A
       JOIN sys.partitions C ON C.object_id = A.objectid AND C.index_id = A.indexid
       JOIN sys.sysobjects D ON A.objectid = D.id
       JOIN sys.objects E ON D.id = E.object_id
       JOIN sys.schemas F ON E.schema_id = F.schema_id
WHERE A.nm_indice NOT IN
	(
		'IX_transacao_cte_cd_documento', -- transacao_cte
		'IX_Transacao_Cte_cd_documento_data_emissao_documento_nota_consultada_cod_retorno_sefaz_Includes', -- transacao_cte
		'IX_transacao_cte_data_emissao_documento_cd_documento_id_Includes', -- transacao_cte
		'IX_transacao_cte_id_cd_documento_Includes', -- transacao_cte
		'IXC_data_inclusao_partition', -- transacao_cte
		'IX_doc_cte_nfe_cd_doc_cte_Includes', -- doc_cte_nfe
		'IX_doc_cte_nfe_chave_acesso', -- doc_cte_nfe
		'IX_doc_cte_nfe_serie_numero', -- doc_cte_nfe
		'IXC_ano_mes_inclusao_partition' -- doc_cte_nfe
	) -- Ignora indices particionados que estão sendo tratados em outra stored procedure

-- All indexes
IF (@Debug = 1)
BEGIN
	SELECT * FROM #historico_fragmentacao_indice
END

IF Object_id('tempdb..#Indices_Fragmentados') IS NOT NULL
  DROP TABLE #indices_fragmentados -- Gera Script - REBUILD

SELECT
	IDENTITY(int, 1, 1) Id, nm_tabela,
    CASE
        WHEN nm_indice IS NULL
		THEN 'ALTER TABLE ' + nm_schema + '.[' + nm_tabela + '] REBUILD'
		ELSE 'ALTER INDEX [' + nm_indice + '] ON ' + nm_schema + '.[' + nm_tabela +
			CASE WHEN avg_fragmentation_in_percent < @Fragmentation_To_Rebuild_In_Percent
			THEN '] REORGANIZE'
			ELSE '] REBUILD with (PAD_INDEX = ON,FILLFACTOR =80,SORT_IN_TEMPDB =ON, ONLINE =ON)'
			END
	END Comando, page_count, avg_fragmentation_in_percent
INTO #indices_fragmentados
FROM #historico_fragmentacao_indice A WITH(nolock)
WHERE	dt_referencia >= Cast(Floor(Cast(Getdate() AS FLOAT)) AS DATETIME) AND
		(
			(
				avg_fragmentation_in_percent >= @Fragmentation_To_Reorganize_In_Percent AND nm_indice IS NOT NULL
			)
            OR
			(
				nm_indice IS NULL AND avg_fragmentation_in_percent > @Fragmentation_To_Rebuild_In_Percent
			)
		) AND
		Page_Count > @Min_Total_Pages
ORDER  BY nm_indice

-- All fragmented indexes
IF (@Debug = 1)
BEGIN
	SELECT * FROM #indices_fragmentados
END

-- Rebuild/Reorganize index one by one
DECLARE @Id AS INT, @SQLSTRING AS NVARCHAR(max)
WHILE EXISTS (SELECT DISTINCT (comando) FROM #indices_fragmentados)
  BEGIN

      SELECT TOP 1 @Id = id, @SQLString = comando FROM   #indices_fragmentados

	  PRINT @SQLString

	  /** Descomente a linha abaixo para executar */
      EXECUTE sp_executesql @SQLString
      
      DELETE FROM #indices_fragmentados WHERE  comando = @SQLString
  END
END

SET NOCOUNT OFF

GO


