/**
    Creating Audit database/tables
*/
USE MASTER
GO

CREATE DATABASE AuditLogs
GO

USE AuditLogs
GO

-- Table to save the audit logs. You can use it to save the results from .sqlaudit files and improve the searching
-- Reference: https://docs.microsoft.com/pt-br/sql/relational-databases/system-functions/sys-fn-get-audit-file-transact-sql?view=sql-server-ver16
CREATE TABLE Logs (
	id INT IDENTITY(1,1) PRIMARY KEY,
	event_time DATETIME,
	action_id VARCHAR(4),
	action_description VARCHAR(40),
	user_name VARCHAR(128), -- SYSNAME,
	server_instance_name VARCHAR(128), -- SYSNAME,
	database_name VARCHAR(128), -- SYSNAME,
	schema_name VARCHAR(128), -- SYSNAME,
	object_name VARCHAR(128), -- SYSNAME,
	statement NVARCHAR(4000)
)
GO

CREATE NONCLUSTERED INDEX aux_index ON Logs (event_time, action_id, database_name)
GO

-- Table to save the results from a specific filter runned over Logs table
-- This is used by a Stored Procedure
CREATE TABLE Temp_Logs_Filter_Results (
	id int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	keyword varchar(20) NOT NULL,
	column_name_keyword_was_found varchar(20) NOT NULL,
	event_time datetime NULL,
	action_id varchar(4) NULL,
	action_description varchar(40) NULL,
	user_name varchar(128) NULL,
	server_instance_name varchar(128) NULL,
	database_name varchar(128) NULL,
	schema_name varchar(128) NULL,
	object_name varchar(128) NULL,
	statement nvarchar(4000) NULL
)
GO

-- Table used to specific keywords
-- This is used by a Stored Procedure
CREATE TABLE keywords (
	keyword VARCHAR(20) PRIMARY KEY
)
GO