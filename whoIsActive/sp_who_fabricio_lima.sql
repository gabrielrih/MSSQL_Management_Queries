use master
Go
select cast(DATEDIFF(HOUR,B.start_time,GETDATE())/86400 as varchar)+'d '
            +cast((DATEDIFF(SECOND,B.start_time,GETDATE())/3600)%24 as varchar)+'h '
             +cast((DATEDIFF(SECOND,B.start_time,GETDATE())/60)%60 as varchar)+'m '
             +cast(DATEDIFF(second,B.start_time,GETDATE())%60 as varchar)+'s' AS Duracao
             , A.session_id as Sid, A.status, login_name
             , B.start_time, B.command
             , B.percent_complete
             , B.last_wait_type
             --, case (cast(B.last_wait_type as varchar) like 'LCK_M_X') then 
             , D.text
             , db_name(cast(B.database_id as varchar)) NmDB
             , C.last_read
             , C.last_write
             , program_name
             , login_time
from sys.dm_exec_sessions A 
             join sys.dm_exec_requests B on A.session_id = B.session_id
                           JOIN sys.dm_exec_connections C on B.session_id = C.session_id
                           CROSS APPLY sys.dm_exec_sql_text(C.most_recent_sql_handle) D 
where /*A.status = 'running' and */A.session_id > 50 and A.session_id <> @@spid
order by B.start_time