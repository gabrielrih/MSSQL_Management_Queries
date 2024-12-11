SELECT 
    dp.name AS UserName,
    drp.name AS RoleName
FROM 
    sys.database_principals dp
INNER JOIN 
    sys.database_role_members drm
ON 
    dp.principal_id = drm.member_principal_id
INNER JOIN 
    sys.database_principals drp
ON 
    drm.role_principal_id = drp.principal_id
WHERE 
    dp.name = 'username'
GO
