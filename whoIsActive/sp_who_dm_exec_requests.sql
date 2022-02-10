select
r.session_id,
s.login_name,
r.blocking_session_id,
r.wait_type,
r.wait_time,
r.status,
c.client_net_address,
s.host_name,
s.program_name,
st.text, s.status
from sys.dm_exec_requests r
inner join sys.dm_exec_sessions s
on r.session_id = s.session_id
left join sys.dm_exec_connections c
on r.session_id = c.session_id
outer apply sys.dm_exec_sql_text(r.sql_handle) st
where client_net_address is not null and text is not null and s.status = 'running'