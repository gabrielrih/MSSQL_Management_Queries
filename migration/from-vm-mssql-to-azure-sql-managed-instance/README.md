# Migration from VM MSSQL to Azure SQL Managed Instance
This is an example of OFFLINE migration from MSSQL into a Virtual Machine (IaaS) to Azure SQL Managed Instance (PaaS).

The thing is, when I made this test/search there is no way to send FULL backup and restore it with NORECOVERY to after send the LOG backups (Managed Instance limitation).

So, what this scripts make is to performe a FULL BACKUP and send it to a Storage Account. Then, a second script just take this backup and restore it in the target.