-- *.mdf
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA, FILENAME = 'C:\TEMP\TreinamentoDBA.mdf')

-- *.ldf
ALTER DATABASE TreinamentoDBA MODIFY FILE ( NAME = TreinamentoDBA_log, FILENAME = 'C:\TEMP\TreinamentoDBA_log.ldf')
