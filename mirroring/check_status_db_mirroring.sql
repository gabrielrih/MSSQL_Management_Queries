/**
    Verifica o estado das DBs em mirroring
    gr14171 em 08/06/2021
*/
SELECT 
   d.name  as [Mirrored database],
   mirroring_state_desc as [Mirrored database state],
   mirroring_role_desc as [Mirrored database role],
   mirroring_partner_instance as [Mirrored database instance],
   case(m.mirroring_witness_state_desc) when 'Unknown' then 'No Witness Server Configured'
      else m.mirroring_witness_name end as 'Witness Server'
FROM 
  sys.database_mirroring M inner join SYS.DATABASES d
  on m.database_id = d.database_id
WHERE mirroring_state_desc is not null 
ORDER BY d.name,mirroring_state_desc

GO