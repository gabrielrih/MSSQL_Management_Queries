/**
	All jobs history in a day
*/
select b.name, b.description, a.step_id, a.step_name, a.message, a.run_status, a.run_date, a.run_time, a.run_duration  from msdb.dbo.sysjobhistory a
inner join msdb.dbo.sysjobs b on a.job_id = b.job_id
where run_date = '20210611' -- format yyyyMMdd
order by run_time