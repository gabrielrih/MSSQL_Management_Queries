/*******************************************************************************************************************************
(C) 2015, Fabrício Lima Soluções em Banco de Dados

Site: http://www.fabriciolima.net/

Feedback: contato@fabriciolima.net
*******************************************************************************************************************************/

--------------------------------------------------------------------------------------------------------------------------------
--	1)	Criação de uma database via interface gráfica (Dever de Casa)
--------------------------------------------------------------------------------------------------------------------------------
--	1.1) No "Object Explorer" -> Botão direito em "Databases" -> "New Database"

--	1.1.1) Na aba "General":
--	Colocar o Nome
--	Alterar o Tamanho Inicial dos arquivos de dados e Logs
--	Alterar o autogrowth de dados e logs
--	Alterar a localização dos arquivos

--	1.1.2) Na aba "Options"
--	Definir o "Recovery Model"


--------------------------------------------------------------------------------------------------------------------------------
--	2)	Page Verify Option
--------------------------------------------------------------------------------------------------------------------------------
--	Query para conferir o valor da opção "Page Verify" das bases de dados
select name, page_verify_option_desc
from sys.databases

--	OBS:	Para verificar essa opção via interface gráfica, basta clicar com o botão direito em cima da database -> "Properties"
--			-> "Options" -> "Recovery" -> "Page Verify"

--	2.1)	Criação de uma database chamada "Checksum" e realização de um teste de corrupção. Essa base está com a opção CHECKSUM marcada.
--	Criação da database
USE master 
IF DATABASEPROPERTYEX (N'CHECKSUM', N'Version') > 0
BEGIN
	ALTER DATABASE CHECKSUM SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE CHECKSUM;
END

CREATE DATABASE CHECKSUM 

USE CHECKSUM;

--	Criação da tabela que vamos corromper
CREATE TABLE [RandomData](
	[c1]  INT IDENTITY,
	[c2]  CHAR (8000) DEFAULT 'a'
);
GO

--	Inserindo 10 linhas na tabela de uma vez
INSERT INTO [RandomData] DEFAULT VALUES;
GO 10

--	Escolhendo uma das páginas dessa database para corromper. Vou escolher a página de número 118 (coluna PagePID)
DBCC IND (N'CHECKSUM', N'RandomData', -1);
GO

/*******************************************************************************************************************************
----------------------------------------------------- <<< PERIGO!!!!! >>> ------------------------------------------------------
*******************************************************************************************************************************/
--	Comando para corromper uma base de dados ******* NUNCA RODEM ISSO EM UMA BASE DE PRODUÇÃO!!!!!!!! 
ALTER DATABASE CHECKSUM SET SINGLE_USER;
GO
DBCC WRITEPAGE (N'CHECKSUM', 1, 147, 0, 2, 0x0000, 1);
GO
ALTER DATABASE CHECKSUM SET MULTI_USER;
GO
/*******************************************************************************************************************************
----------------------------------------------------- <<< PERIGO!!!!! >>> ------------------------------------------------------
*******************************************************************************************************************************/

--	Como a base está marcada como CHECKSUM, ao tentar executar o SELECT o SQL Server já identifica uma corrupção
SELECT	*
FROM [CHECKSUM].[dbo].[RandomData];

--	DBCC CHECKDB('CHECKSUM')

--	Essa tabela mostra quantas vezes tentaram realizar uma consulta nessa página corrompida
SELECT	* FROM	[msdb].[dbo].[suspect_pages];

--	Faça um novo select 
SELECT	*
FROM [CHECKSUM].[dbo].[RandomData];
GO

--	Valide que a coluna "error_count" aumentou seu valor
SELECT	*
FROM [msdb].[dbo].[suspect_pages];
GO

--------------------------------------------------------------------------------------------------------------------------------
--	2.2)	Criação de uma database chamada "TornPageDetection" e realização de um teste de corrupção.
--------------------------------------------------------------------------------------------------------------------------------
--	Essa base está com a opção "TornPageDetection" marcada.

--	Criação da database
USE master 
IF DATABASEPROPERTYEX (N'TornPageDetection', N'Version') > 0
BEGIN
	ALTER DATABASE TornPageDetection SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE TornPageDetection;
END

CREATE DATABASE TornPageDetection 

--	Alteração da opção de verificação para "TornPageDetection"
ALTER DATABASE TornPageDetection SET PAGE_VERIFY TORN_PAGE_DETECTION

USE TornPageDetection;

--	Conferindo a configuração
select name, page_verify_option_desc
from sys.databases

--	Criação da tabela que vamos corromper
CREATE TABLE [RandomData] (
	[c1]  INT IDENTITY,
	[c2]  CHAR (8000) DEFAULT 'a');
GO

--	Inserindo 10 linhas na tabela de uma vez
INSERT INTO [RandomData] DEFAULT VALUES;
GO 10

--	Escolhendo uma das páginas dessa database para corromper. Vou escolher a página de número 118
DBCC IND (N'TornPageDetection', N'RandomData', -1);
GO

/*******************************************************************************************************************************
----------------------------------------------------- <<< PERIGO!!!!! >>> ------------------------------------------------------
*******************************************************************************************************************************/
--	Comando para corromper uma base de dados ******* NUNCA RODEM ISSO EM UMA BASE DE PRODUÇÃO!!!!!!!! 
ALTER DATABASE TornPageDetection SET SINGLE_USER;
GO
DBCC WRITEPAGE (N'TornPageDetection', 1, 144, 0, 2, 0x0000, 1);
GO
ALTER DATABASE TornPageDetection SET MULTI_USER;
GO
/*******************************************************************************************************************************
----------------------------------------------------- <<< PERIGO!!!!! >>> ------------------------------------------------------
*******************************************************************************************************************************/

--	Com esse modo de verificação, o SQL Server não pega a corrupção quando realiza uma consulta
SELECT	*
FROM	TornPageDetection.[dbo].[RandomData];

--	Só executando um checkdb é possível pegar a corrupção dessa database.
DBCC CHECKDB('TornPageDetection')

/* Código Extra */
-- Uso essa query para fazer a primeira validação do banco de dados de novos clientes
SELECT database_id,
 CONVERT(VARCHAR(25), DB.name) AS dbName,
 CONVERT(VARCHAR(10), DATABASEPROPERTYEX(name, 'status')) AS [Status],
 state_desc,
 (SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS DataFiles,
 (SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS [Data MB],
 (SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS LogFiles,
 (SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS [Log MB],
 user_access_desc AS [User access],
 recovery_model_desc AS [Recovery model],
 compatibility_level [compatibility level],
 CONVERT(VARCHAR(20), create_date, 103) + ' ' + CONVERT(VARCHAR(20), create_date, 108) AS [Creation date],
 -- last backup
 ISNULL((SELECT TOP 1
 CASE type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction log' END + ' – ' +
 LTRIM(ISNULL(STR(ABS(DATEDIFF(DAY, GETDATE(),backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
 CONVERT(VARCHAR(20), backup_start_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
 CONVERT(VARCHAR(20), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
 ' (' + CAST(DATEDIFF(second, BK.backup_start_date,
 BK.backup_finish_date) AS VARCHAR(4)) + ' '
 + 'seconds)'
 
 FROM msdb..backupset BK WHERE BK.database_name = DB.name ORDER BY backup_set_id DESC),'-') AS [Last backup],
 CASE WHEN is_fulltext_enabled = 1 THEN 'Fulltext enabled' ELSE '' END AS [fulltext],
 CASE WHEN is_auto_close_on = 1 THEN 'autoclose' ELSE '' END AS [autoclose],
 page_verify_option_desc AS [page verify option],
 CASE WHEN is_read_only = 1 THEN 'read only' ELSE '' END AS [read only],
 CASE WHEN is_auto_shrink_on = 1 THEN 'autoshrink' ELSE '' END AS [autoshrink],
 CASE WHEN is_auto_create_stats_on = 1 THEN 'auto create statistics' ELSE '' END AS [auto create statistics],
 CASE WHEN is_auto_update_stats_on = 1 THEN 'auto update statistics' ELSE '' END AS [auto update statistics],
 CASE WHEN is_in_standby = 1 THEN 'standby' ELSE '' END AS [standby],
 CASE WHEN is_cleanly_shutdown = 1 THEN 'cleanly shutdown' ELSE '' END AS [cleanly shutdown]
  FROM sys.databases DB
 ORDER BY dbName, [Last backup] DESC, NAME

 
--------------------------------------------------------------------------------------------------------------------------------
--	3)	Tipos de Dados
--------------------------------------------------------------------------------------------------------------------------------
--	3.1)	Testes como tipo de dados numeric

--	"Numeric(9,2)" - O Maior número que pode ser armazenado é 9.999.999,99. 9 dígitos no total com 7 dígitos antes da vírgula e 2 depois.
declare @TesteNumeric numeric(9,2)
set @TesteNumeric = 9999999.99

--	Diminuir casas antes da vírgula e adicionar depois funciona
declare @TesteNumeric numeric(9,2)
set @TesteNumeric = 999999.999

--	O contrário não funciona
declare @TesteNumeric numeric(9,2)
set @TesteNumeric = 99999999.9

--	Numeric(9,4) - O Maior número que pode ser armazenado é 99.999,9999. 9 dígitos no total com 5 dígitos antes da vírgula e 4 depois.
declare @TesteNumeric numeric(9,4)
set @TesteNumeric = 9.99999999

-- Tamanho numeric

USE TreinamentoDBA

IF OBJECT_ID('Teste_Numeric_9') IS NOT NULL 
	DROP TABLE Teste_Numeric_9

IF OBJECT_ID('Teste_Numeric_15') IS NOT NULL 
	DROP TABLE Teste_Numeric_15
		
CREATE TABLE Teste_Numeric_9(
	Campo NUMERIC(9,2))

CREATE TABLE Teste_Numeric_15(
	Campo NUMERIC(15,2))

INSERT INTO Teste_Numeric_9(Campo)
SELECT 100
GO 1000

INSERT INTO Teste_Numeric_9
SELECT Campo FROM Teste_Numeric_9
GO 10

INSERT INTO Teste_Numeric_15(Campo)
SELECT 100
GO 1000

INSERT INTO Teste_Numeric_15
SELECT Campo FROM Teste_Numeric_15
GO 10

EXEC sp_spaceused Teste_Numeric_9
EXEC sp_spaceused Teste_Numeric_15

SELECT 14.2/18.3 --23% menos



--------------------------------------------------------------------------------------------------------------------------------
--	3.2)	Testes com os tipos  char e varchar
--------------------------------------------------------------------------------------------------------------------------------
DECLARE @CharName Char(20) = 'Fabricio',
		@VarCharName VarChar(20) = 'Fabricio'

SELECT DATALENGTH(@CharName) CharSpaceUsed,
	   DATALENGTH(@VarCharName) VarCharSpaceUsed

--------------------------------------------------------------------------------------------------------------------------------
--	3.3)	Testes com os tipos varchar x nvarchar
--------------------------------------------------------------------------------------------------------------------------------
DECLARE @NVarCharName NVarChar(20) = 'Fabricio',
		@VarCharName VarChar(20) = 'Fabricio'

SELECT DATALENGTH(@NVarCharName) NVarCharSpaceUsed,
	   DATALENGTH(@VarCharName) VarCharSpaceUsed

-- Voltar para os slides

--------------------------------------------------------------------------------------------------------------------------------
--	4)	Trabalhando com Constraints no SQL Server (Dever de Casa)
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
--	4.1)	PRIMARY KEY (apenas uma por tabela)
--------------------------------------------------------------------------------------------------------------------------------
--	Criando uma database chamada TreinamentoDBA para realizar os testes
USE master 
IF DATABASEPROPERTYEX (N'TreinamentoDBA', N'Version') > 0
BEGIN
	ALTER DATABASE TreinamentoDBA SET SINGLE_USER
		WITH ROLLBACK IMMEDIATE;
	DROP DATABASE TreinamentoDBA;
END

create database TreinamentoDBA

--	Logar na base de dados
use TreinamentoDBA

--	A primary key pode ser criada de duas formas:

--------------------------------------------------------------------------------------------------------------------------------
--	4.1.1)	Sem especificar o nome da primary key. O Próprio SQL Server que escolhe o nome dela.
--------------------------------------------------------------------------------------------------------------------------------
if object_id('Empregado') is not null
	drop table Empregado

--	Sem especificar o nome
CREATE TABLE Empregado( 
	Id_Empregado int identity PRIMARY KEY,
	Nome VARCHAR(50),
	Salario numeric(9,2),
	Fl_Estado_Civil tinyint
)

--	Selecionar o nome da tabela e olhar o nome da PK com o ALT+F1

--------------------------------------------------------------------------------------------------------------------------------
--	4.1.2)	Especificando o nome da primary key
--------------------------------------------------------------------------------------------------------------------------------
--	Especificando o nome
if object_id('Empregado') is not null
	drop table Empregado

CREATE TABLE Empregado( 
	Id_Empregado int identity,
	Nome VARCHAR(50),
	Salario numeric(9,2),
	Fl_Estado_Civil tinyint,
	CONSTRAINT PK_Empregado PRIMARY KEY (Id_Empregado) --*****
);

--	Selecionar o nome da tabela e olhar o nome da PK com o ALT + F1

--	É bem aconselhável que toda tabela tenha uma primary key. Mas não é obrigatório!!!
--	Muitas vezes ela é criada no campo identity, que é um campo inteiro e cresce de forma incremental. 
--	O defaut do SQL Server é criar a primary key como um índice clustered e veremos no módulo de tuning que um índice clustered
--	deve ser o menor possível e se fragmentar menos.


--------------------------------------------------------------------------------------------------------------------------------
--	4.2)	FOREIGN KEY
--------------------------------------------------------------------------------------------------------------------------------
--	Caso real para explicar o que é uma FK e sua importancia
--	Precisamos criar uma estrutura para armazenar alguns contadores de performance.

--------------------------------------------------------------------------------------------------------------------------------
--	4.2.1)	Armazenamento de todos os dados em uma mesma tabela
--------------------------------------------------------------------------------------------------------------------------------
if OBJECT_ID('Contador') is not null
	drop table Contador

CREATE TABLE Contador  (
	Id_Contador INT IDENTITY ,
	Nm_Contador VARCHAR(50) ,
	[Dt_Log] [DATETIME] ,
	[Valor] [INT]
)

--	Inserindo 10 registros na tabela criada
insert into Contador(Nm_Contador,Dt_Log,Valor)
select 'Page Life Expectancy', getdate(), 5655
GO 10

select * from Contador

--------------------------------------------------------------------------------------------------------------------------------
--	4.2.2)	Armazenamento dos dados em uma estrutura normalizada
--------------------------------------------------------------------------------------------------------------------------------
--	A tabela contador terá apenas um ID para cada contador e sua descrição
if OBJECT_ID('Contador') is not null
	drop table Contador

CREATE TABLE Contador(
	Id_Contador smallint identity, 
	Nm_Contador VARCHAR(50)
)

INSERT INTO Contador (Nm_Contador)
SELECT 'BatchRequests'
INSERT INTO Contador (Nm_Contador)
SELECT 'User_Connection'
INSERT INTO Contador (Nm_Contador)
SELECT 'CPU'
INSERT INTO Contador (Nm_Contador)
SELECT 'Page Life Expectancy'

SELECT * FROM Contador

--	A tabela "Registro_Contador" terá todos os dados. Ao invés de armazenar a descrição dos contadores, agora armazenaremos apenas o ID do contador.
--	Isso gera um ganho grande de espaço e performance.
--	É aí que entra a Foreign Key.
 
--	Criação da tabela
if OBJECT_ID('Registro_Contador') is not null
	drop table Registro_Contador

CREATE TABLE [dbo].[Registro_Contador](
	[Id_Registro_Contador] [int] IDENTITY(1,1) NOT NULL,
	[Dt_Log] [datetime] NULL,
	[Id_Contador] smallint NULL,
	[Valor] [int] NULL
) ON [PRIMARY]

--	Inserindo 10 registros na tabela
insert into Registro_Contador(Dt_Log,Id_Contador,Valor)
select getdate(), 2, 5655
GO 10

--	Validando os resultados já existentes
select * from Registro_Contador
SELECT * FROM Contador

--	Gerando um problema de integridade no banco de dados
delete from contador
where Id_Contador = 2

--	Testando o insert de um Id que não existe na tabela de contadores. ID de número "5". Gera outro problema de integridade no banco de dados.
insert into Registro_Contador(Dt_Log,Id_Contador,Valor)
select getdate(), 5, 5655

--	O insert funcionou e deixou a base inconsistente. A foreign key serve para garantir essa integridade de dados.
--	Ela fará com que eu só possa usar contadores que já estão cadastrados na tabela contador.

--	Tentando criar uma FK
alter table Registro_Contador
ADD constraint FK01_Registro_Contador foreign key (Id_Contador) references Contador(Id_Contador)
--	Erro porque uma Fk tem que referenciar uma Chave primaria e não criamos uma chame primária na tabela Contador

--	Criando uma PK na tabela contador
Alter table Contador
ADD CONSTRAINT PK_Contador primary key (Id_Contador)

--	Tentando criar uma FK na tabela 
alter table Registro_Contador
ADD constraint FK01_Registro_Contador foreign key (Id_Contador) references Contador(Id_Contador)
--	Erro porque existe o registro "5" que é inconsistente para essa estrutura

--	Retirando as inconsistencias da tabela
update Registro_Contador
set Id_Contador = 3

--	Agora conseguimos criar a FK
alter table Registro_Contador
ADD constraint FK01_Registro_Contador foreign key (Id_Contador) references Contador(Id_Contador)

--	Para gravar
--	Uma FK tem que referenciar uma PK. (Mais um motivo para toda tabela sua ter uma PK)
--	A FK garante a consistencia dos dados entre duas tabelas e ajuda na normalização para melhorar a performance do banco de dados


--------------------------------------------------------------------------------------------------------------------------------
--	4.3)	UNIQUE CONSTRAINT(pode criar várias por tabela)
--------------------------------------------------------------------------------------------------------------------------------
--	No dia a dia uma constraint unique é criada para garantir que mais colunas sejam únicas além da PK
--	Nesse caso abaixo queremos que as colunas CPF e PIS também sejam únicas, além do ID do empregado.

if object_id('Empregado') is not null
	drop table Empregado

CREATE TABLE Empregado( 
	Id_Empregado int identity,
	Nome VARCHAR(50),
	Salario numeric(9,2),
	Fl_Estado_Civil tinyint,
	CPF varchar(11),
	PIS varchar(20),
	CONSTRAINT PK_Empregado PRIMARY KEY (Id_Empregado),
	CONSTRAINT UQ01_Empregado UNIQUE (CPF), -- ********
	CONSTRAINT UQ02_Empregado UNIQUE (PIS)  -- ********
);

--	Ao tentar executar os dois inserts abaixo, o segundo dará um erro devido a duplicidade do CPF
insert into Empregado (Nome, Salario, Fl_Estado_Civil, CPF, PIS) 
select 'Sebastião Salgado Doce', 675, 1, '12345678900', '1234567890045654'

insert into Empregado (Nome, Salario, Fl_Estado_Civil, CPF, PIS) 
select 'João Cara de José', 1000, 2,'12345678900','99999678900456545'

--	Verificando os dados inseridos na tabela
select * from Empregado

--	O defaut do SQL Server é criar a unique key como um índice nonclustered. 
--	Então toda vez que você criar uma unique constraint o SQL criará um índice nonclustered com as colunas dessa constraint.

--	Diferenças entre UNIQUE x Primary KEY
--	UNIQUE permite um valor NULL, Primary KEY não.
--	UNIQUE cria um indice nonclustered por default, primary key cria um índice clustered.
--	Uma tabela pode ter mais de uma constraint UNIQUE, mas só pode ter uma primary key.


--------------------------------------------------------------------------------------------------------------------------------
--	4.4)	CHECK CONSTRAINTS
--------------------------------------------------------------------------------------------------------------------------------
if object_id('Empregado') is not null
	drop table Empregado

--	Segue abaixo a sintaxe para a criação de duas constraints do tipo CHECK
CREATE TABLE Empregado( 
	Id_Empregado int identity,
	Nome VARCHAR(50) NOT NULL,
	Salario numeric(9,2),
	Fl_Estado_Civil tinyint, -- 1- solteiro, 2-casado
	CONSTRAINT CK01_Empregado CHECK (Salario > 0), -- ********
	CONSTRAINT CK02_Empregado CHECK (Fl_Estado_Civil in (1,2)) -- ********
)

insert into Empregado(Nome, Salario, Fl_Estado_Civil)
select 'Fabricio Lima', 675, 2

insert into Empregado(Nome, Salario, Fl_Estado_Civil)
select 'Chefe do Fabricio Lima', 30000, 1

insert into Empregado(Nome, Salario, Fl_Estado_Civil)
select 'Joselito Estagiário', -100, 2

insert into Empregado(Nome, Salario, Fl_Estado_Civil) -- 3 - dando um tempo 
select 'Hidráulico Oliveira', 1000, 3


--------------------------------------------------------------------------------------------------------------------------------
--	4.5)	DEFAULT
--------------------------------------------------------------------------------------------------------------------------------
--	Também existem duas formas de criar uma constraint DEFAULT. Uma onde escolhemos o nome da DEFAULT e outra onde o próprio SQL Server escolhe o nome.

4.5.1) A forma mais simples é deixar o SQL Server escolher o nome conforme abaixo

if object_id('Empregado') is not null
	drop table Empregado

CREATE TABLE Empregado( 
	Id_Empregado int identity,
	Nome VARCHAR(50) NOT NULL,
	Salario numeric(9,2) DEFAULT (700), -- Quando não for inserido um salário, vamos colocar o DEFAULT de 700,00
	Fl_Estado_Civil tinyint
)

--------------------------------------------------------------------------------------------------------------------------------
--	4.5.2)	A forma mais bonita é definirmos um padrão de nomes para esse tipo de constraint
--------------------------------------------------------------------------------------------------------------------------------
if object_id('Empregado') is not null
	drop table Empregado

CREATE TABLE Empregado(
	Id_Empregado int identity,
	Nome VARCHAR(50) NOT NULL,
	Salario numeric(9,2),
	Fl_Estado_Civil tinyint
)

--	Adicionando a constraint na tabela que foi criada
alter table Empregado
add constraint DF01_Empregado DEFAULT 700 FOR Salario
  
--	Inserindo um novo colaborador sem colocar o salário
insert into Empregado (Nome,Fl_Estado_Civil) 
select 'Sebastião Salgado Doce',  1

select * from Empregado

--	Fonte dos nomes utilizados nessa DEMO: http://algunsnomesestranhos.blogspot.com.br/


--------------------------------------------------------------------------------------------------------------------------------
--	5)	Detach e Attach \ Movimentação de Arquivo
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
--	5.1)	Detach
--------------------------------------------------------------------------------------------------------------------------------
--	Para fazer detach é necessário matar todas as conexões que estão utilizando aquela base de dados

--------------------------------------------------------------------------------------------------------------------------------
--	5.1.1)	Fazendo um detach via interface grafica
--------------------------------------------------------------------------------------------------------------------------------
--	Clique com o botão direito em cima da database que quer fazer o Detach -> "Task" -> "Detach"
--	Valide se tem alguma conexão aberta. Se tiver é muito válido encontrar quem está utilizando essa base para saber se ela realmente pode
--	ser retirada do banco de dados

--	Segue query para encontrar as conexões nessa database
select *
from sys.sysprocesses
where	Db_name(dbid) = 'TreinamentoDBA'
		and spid > 50	-- Apenas conexoes de usuários. spid < 50 é conexão de sistema.

--	Detach via Script. Com esse script, o SQL fecha todas as conexões da base deixando ela em SINGLE_USER mode.
USE [master]
GO
ALTER DATABASE [TreinamentoDBA] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'TreinamentoDBA'
GO

--------------------------------------------------------------------------------------------------------------------------------
--	5.1.2)	Fazendo um attach via interface gráfica
--------------------------------------------------------------------------------------------------------------------------------
--	No "Object Explorer" -> Botão direito em "Databases" -> "Attach" -> Clique em "Add" 
--	-> Encontre o arquivo ".mdf" da database, selecione e clique em "OK".

--	Em seguida confira o caminho do arquivo de log que também é selecionado automaticamente pelo SQL.

--	Se estiver tudo certo, clique em "OK".

--	O script abaixo realiza o mesmo procedimento que acabamos de realizar via interface gráfica
USE [master]
GO
CREATE DATABASE [TreinamentoDBA] ON 
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TreinamentoDBA.mdf' ),
( FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TreinamentoDBA_log.ldf' )
 FOR ATTACH
GO

--------------------------------------------------------------------------------------------------------------------------------
--	5.2)	Movimentação de Arquivo
--------------------------------------------------------------------------------------------------------------------------------
--	Para fazer deixar uma base offline é necessário matar todas as conexões que estão utilizando essa base de dados
-- https://technet.microsoft.com/en-us/library/gg452698.aspx

-- 2. Verificar se existe alguma conexão na database. Se existir, deve fazer matar com o KILL.
USE master 
Declare @SpId as varchar(5)

if(OBJECT_ID('tempdb..#Processos') is not null) drop table #Processos

select Cast(spid as varchar(5))SpId
into #Processos
from master.dbo.sysprocesses A
 join master.dbo.sysdatabases B on A.DbId = B.DbId
where B.Name ='TreinamentoDBA'

-- Mata as conexões
while (select count(*) from #Processos) >0
begin
 set @SpId = (select top 1 SpID from #Processos)
   exec ('Kill ' +  @SpId)
 delete from #Processos where SpID = @SpId
end

-- 3. Altera o status da database para OFFLINE:
ALTER DATABASE TreinamentoDBA SET OFFLINE

-- 4. Mova o arquivo (*.mdf, *.ldf, *.ndf) para o novo local e altere o FILENAME para o novo caminho

-- Busca o nome logico e o caminho dos arquivos de dados e log associados a database:
SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('TreinamentoDBA');

-- *.mdf
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA, FILENAME = 'C:\TEMP\TreinamentoDBA.mdf')

-- *.ldf
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA_log, FILENAME = 'C:\TEMP\TreinamentoDBA_log.ldf')

-- 5. Altera o status da database para ONLINE:
ALTER DATABASE TreinamentoDBA SET ONLINE

-- Conferindo o resultado após a alteração

-- Local dos arquivos
SELECT name, physical_name 
FROM sys.master_files 
WHERE database_id = DB_ID('TreinamentoDBA');

--------------------------------------------------------------------------------------------------------------------------------
--	6)	Linked Server (Está no Vídeo)
--------------------------------------------------------------------------------------------------------------------------------

--	6.1) O primeiro Passo para criar um LS entre dois servidores SQL é ter um usuário no servidor de destino com o acesso restrito ao que voce quer acessar
--	Na minha DEMO vou usar um usuário chamado TesteLS que tem acesso de leitura em uma base qualquer.
--	Senha: 123456

--	6.2) No "Object Explorer" -> "Server Objects" -> Clique com o botão direito em "Linked Servers" -> "New Linked Server"
--	Em seguida, altere o "Server Type" para "SQL Server" e coloque o nome do servidor onde está indicado "Linked server".
--	Na aba "Security" selecione a opção "Be made using this security context" e coloque o login e senha que você criou no servidor destino.
--	De um "OK" para concluir a criação do Linked Server.

-- Nessa demo durante o Treinamento, vou utilizar duas instancias que tenho em uma máquina virtual. 
-- Uma conexão da instancia SQLAG01\SQLSTD2016_AG vai fazer um select na 
-- instancia SQLAG01\SQLSTD2016, na database TreinamentoDBA, Tabela TESTE_LinkedServer.

--	6.3) Para acessar um servidor via linked server você tem que colocar o caminho completo no select
select *
from [Nome Linked Server].[Nome Database].[schema].[Nome Tabela]

--	[Nome Linked Server] normalmente é igual ao nome do servidor de destino.

select *
from [SQLAG01\SQLSTD2016].TreinamentoDBA.dbo.TESTE_LinkedServer


--------------------------------------------------------------------------------------------------------------------------------
--	7)	Shrink
--------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------
--	7.1) Cenário do dia a dia: Executaram um UPDATE gigante em uma tabela com uma query só! 
--------------------------------------------------------------------------------------------------------------------------------
--	Resultado, o LOG da base está duas vezes o tamanho da base.

--	Analisando o tamanho do log da database TreinamentoDBA
DBCC SQLPERF(LOGSPACE)

--	Para simular esse cenário, vou aumentar o tamanho do log da database Treinamento 
USE [master]
GO
ALTER DATABASE [TreinamentoDBA] MODIFY FILE ( NAME = N'TreinamentoDBA_log', SIZE = 500400KB )

--	Conferindo o tamanho do log da database TreinamentoDBA
DBCC SQLPERF(LOGSPACE)

--	Executo um checkpoint para forçar o SQL a gravar os dados que ainda estão apenas no log para o arquivo de dados.
CHECKPOINT

--	Script para realizar o Shrink do arquivo de log para 100 MB
USE [TreinamentoDBA]
GO
DBCC SHRINKFILE (N'TreinamentoDBA_log' , 100)
GO

--------------------------------------------------------------------------------------------------------------------------------
--	7.2) Realizando o mesmo Shrink via interface gráfica (Dever de casa)
--------------------------------------------------------------------------------------------------------------------------------
--	Para simular esse cenário, vou aumentar o tamanho do log da database TreinamentoDBA 
USE [master]
GO
ALTER DATABASE [TreinamentoDBA] MODIFY FILE ( NAME = N'TreinamentoDBA_log', SIZE = 500400KB )

--	Conferindo o tamanho do log da database TreinamentoDBA
DBCC SQLPERF(LOGSPACE)

--	Para realizar o Shrink clique com o botão direito em cima da database -> "Tasks" -> "Shrink" -> "Files"

--	Em "File Type" altere de "Data" para "Log" -> 

--	no final da tela em "Shrink action" clique na opção do meio para escolher o novo tamanho do arquivo de log

--	Escolhido o tamanho, clique em "OK" para realizar o Shrink

--	Conferindo o tamanho do log da database TreinamentoDBA
DBCC SQLPERF(LOGSPACE)

--------------------------------------------------------------------------------------------------------------------------------
--	7.3) Realizando um Shrink de um arquivo de dados. ***** Somente em último caso!!! ******* (Dever de casa)
--------------------------------------------------------------------------------------------------------------------------------
--	Para simular esse cenário, vou crecer o arquivo de dados para 500 MB
USE [master]
GO
ALTER DATABASE [TreinamentoDBA] MODIFY FILE ( NAME = N'TreinamentoDBA', SIZE = 512000KB )
GO

--	Conferir o tamanho via interface gráfica
use TreinamentoDBA

SELECT
    [file_id],
    [type],
    type_desc,
    data_space_id,
    [name],
    physical_name,
    state,
    state_desc,
    size,
    size * 8 / 1024.00 AS size_in_mb
FROM sys.database_files AS DF

exec sp_spaceused

--	Para realizar o shrink  do arquivo de dados via interface gráfica:

--	Clique com o botão direito em cima da database -> "Tasks" -> "Shrink-Files"

--	Em "File Type" estará selecionado Data -> no final da tela em "Shrink action"
--	clique na opção do meio para escolher o novo tamanho do arquivo de dados

--	Escolhido o tamanho, clique em "OK" para realizar o Shrink.

--	Conferindo novamente o tamanho do arquivo de dados para validar se o shrink foi realizado
SELECT
    [file_id],
    [type],
    type_desc,
    data_space_id,
    [name],
    physical_name,
    state,
    state_desc,
    size,
    size * 8 / 1024.00 AS size_in_mb
FROM sys.database_files AS DF


--------------------------------------------------------------------------------------------------------------------------------
--	7.4) Shrink x Fragmentação
--------------------------------------------------------------------------------------------------------------------------------

-- REFERENCIA: http://www.sqlskills.com/blogs/paul/why-you-should-not-shrink-your-data-files/
-- EXEMPLO SHRINK DATABASE

USE [master];
GO
 
IF DATABASEPROPERTYEX (N'DBMaint2008', N'Version') IS NOT NULL
    DROP DATABASE [DBMaint2008];
GO
 
CREATE DATABASE DBMaint2008;
GO
USE [DBMaint2008];
GO
 
SET NOCOUNT ON;
GO
 
-- Create the 10MB filler table at the 'front' of the data file
CREATE TABLE [FillerTable] (
    [c1] INT IDENTITY,
    [c2] CHAR (8000) DEFAULT 'filler');
GO
 
-- Fill up the filler table
INSERT INTO [FillerTable] DEFAULT VALUES;
GO 1280
 
-- Create the production table, which will be 'after' the filler table in the data file
CREATE TABLE [ProdTable] (
    [c1] INT IDENTITY,
    [c2] CHAR (8000) DEFAULT 'production');
CREATE CLUSTERED INDEX [prod_cl] ON [ProdTable] ([c1]);
GO
 
INSERT INTO [ProdTable] DEFAULT VALUES;
GO 1280
 
-- Check the fragmentation of the production table
SELECT
    [avg_fragmentation_in_percent]
FROM sys.dm_db_index_physical_stats (
    DB_ID (N'DBMaint2008'), OBJECT_ID (N'ProdTable'), 1, NULL, 'LIMITED');
GO

-- Drop the filler table, creating 10MB of free space at the 'front' of the data file
DROP TABLE [FillerTable];
GO
 
-- Shrink file mdf
USE [DBMaint2008]
GO
DBCC SHRINKFILE (N'DBMaint2008' , 13)
GO

 
-- Check the index fragmentation again
SELECT
    [avg_fragmentation_in_percent]
FROM sys.dm_db_index_physical_stats (
    DB_ID (N'DBMaint2008'), OBJECT_ID (N'ProdTable'), 1, NULL, 'LIMITED');

use master

drop database [DBMaint2008]
