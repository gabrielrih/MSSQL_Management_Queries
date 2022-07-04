/**
	Get infos from audit files
	References:
		https://docs.microsoft.com/pt-br/sql/relational-databases/system-functions/sys-fn-get-audit-file-transact-sql?view=sql-server-ver16
		https://cprovolt.wordpress.com/2013/08/02/sql-server-audit-action_id-list/
*/
SELECT event_time ,action_id ,session_server_principal_name AS UserName ,server_instance_name ,database_name ,schema_name, object_name ,statement
FROM sys.fn_get_audit_file(N'C:\AuditDB\*.sqlaudit', DEFAULT, DEFAULT)
--WHERE action_id IN ('UP') and statement LIKE '%usuario%'
ORDER BY event_time ASC
GO