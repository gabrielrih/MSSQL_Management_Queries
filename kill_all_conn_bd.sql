/**
    Mata todas as conexões de uma determinada BD
    Podemos usar, por exemplo, antes de colocar uma BD OFFLINE
*/
USE master 
DECLARE @SpId AS VARCHAR(5)
DECLARE @DBName AS VARCHAR(50)

SET @DBName = 'TreinamentoDBA'


if(OBJECT_ID('tempdb..#Processos') is not null) drop table #Processos

select Cast(spid as varchar(5))SpId
into #Processos
from master.dbo.sysprocesses A
 join master.dbo.sysdatabases B on A.DbId = B.DbId
where B.Name = @DBName

-- Mata as conexoes
while (select count(*) from #Processos) >0
begin
 set @SpId = (select top 1 SpID from #Processos)
   exec ('Kill ' +  @SpId)
 delete from #Processos where SpID = @SpId
end