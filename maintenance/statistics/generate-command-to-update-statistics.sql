/**
    Generate commands to update statistics
*/
DECLARE @horas int
DECLARE @linhas_alteradas int
DECLARE @comando_update nvarchar(300);
 
SET @horas=24
SET @linhas_alteradas=1000
 
--Update all the outdated statistics
DECLARE cursor_estatisticas CURSOR FOR
SELECT 'UPDATE STATISTICS ['+ OBJECT_NAME(id) + '] [' + name + '] with fullscan'
FROM sys.sysindexes
WHERE	STATS_DATE(id, indid) <= DATEADD(HOUR, -@horas, GETDATE()) AND
		rowmodctr>=@linhas_alteradas AND
		id IN (SELECT object_id FROM sys.tables)
  
OPEN cursor_estatisticas;
FETCH NEXT FROM cursor_estatisticas INTO @comando_update;
  
WHILE (@@FETCH_STATUS<> -1)
BEGIN

	--EXECUTE (@comando_update);
	PRINT @comando_update;
  
 FETCH NEXT FROM cursor_estatisticas INTO @comando_update;
 END
  
CLOSE cursor_estatisticas;
DEALLOCATE cursor_estatisticas;
GO
