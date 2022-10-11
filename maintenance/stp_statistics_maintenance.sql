CREATE PROCEDURE [dbo].[stp_statistics_maintenance]
(
   @horas int = 24,
   @linhas_alteradas int = 1000
)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	DECLARE @comando_update nvarchar(300);
 
	--Update all the outdated statistics
	DECLARE cursor_estatisticas CURSOR FOR
	SELECT 'UPDATE STATISTICS '+OBJECT_NAME(id)+' '+name+ ' with fullscan'
	FROM sys.sysindexes
	WHERE	STATS_DATE(id, indid)<=DATEADD(HOUR,-@horas,GETDATE()) AND
			rowmodctr >= @linhas_alteradas AND
			id IN (SELECT object_id FROM sys.tables)
  
	OPEN cursor_estatisticas;
	FETCH NEXT FROM cursor_estatisticas INTO @comando_update;
  
	WHILE (@@FETCH_STATUS<> -1)
	BEGIN
		/*Descomente o comando abaixo para executar */
		EXECUTE (@comando_update);
		PRINT @comando_update;
		FETCH NEXT FROM cursor_estatisticas INTO @comando_update;
	END;
  
	CLOSE cursor_estatisticas;
	DEALLOCATE cursor_estatisticas;

END
GO