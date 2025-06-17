# Migração de Azure Managed Instance (MI) para Azure Managed Instance (MI)

Estratégias:
- Backup / Restore (OFFLINE)
- Copy / Move, via Portal da Azure (ONLINE)
- Transactional Replication (ONLINE)

## Backup / Restore
- Opção offline
- Downtime maior que as opções abaixo
- Tem alguns scripts de exemplo aqui
- Backup:
  - https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-ver17#limitations-of-backuprestore-to-azure-blob-storage
  - https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql?view=sql-server-ver17
- Restore:
  - https://docs.azure.cn/en-us/azure-sql/managed-instance/restore-sample-database-quickstart#use-t-sql-to-restore-from-a-backup-file
  - https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-ver17

## Copy / Move
- Melhor escolha.
- Conseguimos fazer praticamente sem downtime. O downtime fica só no cutover no final do processo.
- A Azure gerencia toda a cópia para nós.
- Limitação: Precisa de conectividade entre as redes (parece que pvt endpoint não funciona)

## Transactional Replication
https://learn.microsoft.com/en-us/sql/relational-databases/replication/transactional/transactional-replication?view=sql-server-ver17

