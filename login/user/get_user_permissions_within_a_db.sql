SELECT
    USER_NAME(dp.grantee_principal_id) AS UserName,
    dp.permission_name,
    dp.state_desc AS PermissionState,
    OBJECT_NAME(dp.major_id) AS ObjectName
FROM
    sys.database_permissions dp
WHERE
    USER_NAME(dp.grantee_principal_id) = 'username'
GO
