/**
	Generate rebuild/reorganize index commands to a especific database
*/

CREATE PROCEDURE [dbo].[stp_index_maintenance]
	@Minimum_to_reorganize AS INT = 10,
	@Minimum_to_rebuild AS INT = 30,
	@Minimum_page_count AS INT = 1000 
AS
BEGIN

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
	[partition_number]				INT,
    [nm_schema]                    VARCHAR(100),
    [avg_fragmentation_in_percent] [NUMERIC](5, 2) NULL,
    [page_count]                   [INT] NULL,
    [fill_factor]                  [TINYINT] NULL,
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
	[partition_number]				VARCHAR(100),
    [nm_schema]                    VARCHAR(100),
    [avg_fragmentation_in_percent] [NUMERIC](5, 2) NULL,
    [page_count]                   [INT] NULL,
    [fill_factor]                  [TINYINT] NULL
)
ON [PRIMARY]

DECLARE @Id_Database INT = Db_id()
DECLARE @Table_ID INT

IF ( Object_id('tempdb..#Tabelas') IS NOT NULL )
  DROP TABLE #tabelas

-- Getting all the database tables
SELECT
	Object_name(s.object_id) AS NAME,
	s.object_id
INTO #tabelas
FROM sys.dm_db_partition_stats s
JOIN sys.tables t ON s.object_id = t.object_id
GROUP BY s.object_id
HAVING SUM(s.used_page_count) > @Minimum_page_count

CREATE CLUSTERED INDEX sk01_#tabelas ON #tabelas(object_id)

-- For each table get the index details
WHILE EXISTS (SELECT TOP 1 object_id FROM #tabelas)
BEGIN
	-- Get a single table
	SELECT TOP 1 @Table_ID = object_id FROM #tabelas

	-- Search for the index fragmentation in the current table
	INSERT INTO #historico_fragmentacao_indice_temp
	SELECT
		GETDATE(),
		@@servername AS Nm_Servidor,
		Db_name(@Id_Database) AS Nm_Database,
		'' AS Nm_Tabela,
		B.NAME AS Nm_Indice,
		partition_number,
		'' AS Nm_Schema,
		avg_fragmentation_in_percent,
		page_count,
		fill_factor,
		A.object_id,
		A.index_id
	FROM sys.Dm_db_index_physical_stats(@Id_Database, @Table_ID, NULL, NULL, NULL) A
	JOIN sys.indexes B
	ON A.object_id = B.object_id AND A.index_id = B.index_id
	WHERE page_count > @Minimum_page_count

	-- Delete from temp table the finished table
	DELETE #tabelas WHERE  object_id = @Table_ID
END

-- DEBUG
--SELECT * FROM #historico_fragmentacao_indice_temp

-- Getting more details about table and schema
INSERT INTO #historico_fragmentacao_indice
SELECT A.dt_referencia,
       A.nm_servidor,
       A.nm_database,
       D.NAME,
       A.nm_indice,
	   A.partition_number,
       F.NAME,
       A.avg_fragmentation_in_percent,
       A.page_count,
       A.fill_factor
FROM #historico_fragmentacao_indice_temp A
JOIN sys.sysobjects D ON A.objectid = D.id
JOIN sys.objects E ON D.id = E.object_id
JOIN sys.schemas F ON E.schema_id = F.schema_id

-- DEBUG
--SELECT * FROM #historico_fragmentacao_indice

IF Object_id('tempdb..#Indices_Fragmentados') IS NOT NULL
  DROP TABLE #indices_fragmentados

-- Generate the scripts (do not execute it yet)
SELECT
	IDENTITY(int, 1, 1) Id,
    nm_tabela,
    CASE
        WHEN nm_indice IS NULL THEN
			'ALTER TABLE ' + nm_schema + '.[' + nm_tabela + '] REBUILD'
        ELSE 
			CASE
				WHEN avg_fragmentation_in_percent < @Minimum_to_rebuild THEN
					'ALTER INDEX [' + nm_indice + '] ON ' + nm_schema + '.[' + nm_tabela + '] REORGANIZE PARTITION = ' + partition_number
				ELSE 
					'ALTER INDEX [' + nm_indice + '] ON ' + nm_schema + '.[' + nm_tabela + '] REBUILD PARTITION = ' + partition_number + ' WITH (PAD_INDEX = ON, FILLFACTOR =80, SORT_IN_TEMPDB =ON, ONLINE =ON)'
			END
	END Comando,
	page_count,
	avg_fragmentation_in_percent
INTO #indices_fragmentados
FROM #historico_fragmentacao_indice A WITH(nolock)
WHERE
	dt_referencia >= Cast(Floor(Cast(Getdate() AS FLOAT)) AS DATETIME) AND
	(
		(avg_fragmentation_in_percent >= @Minimum_to_reorganize AND nm_indice IS NOT NULL)
		OR
		(nm_indice IS NULL AND avg_fragmentation_in_percent > 30)
	)
ORDER BY nm_indice

-- Debug
--SELECT DISTINCT(comando) FROM #indices_fragmentados

-- Executing scripts
--  It may has a lot of repeated commands, so we use the distinct to do not run the same command twice
DECLARE @Id INT;
DECLARE @SQLSTRING VARCHAR(max)
WHILE EXISTS (SELECT DISTINCT(comando) FROM #indices_fragmentados)
BEGIN
	-- Get one command to run
	SELECT TOP 1 @Id = id, @SQLString = comando
	FROM #indices_fragmentados

	-- Run command
	PRINT @SQLString
	--EXECUTE sp_executesql @SQLString

	-- Delete from the temp table the executed command
	DELETE FROM #indices_fragmentados WHERE id = @Id;
END

SET NOCOUNT OFF

END