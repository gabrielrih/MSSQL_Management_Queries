/* Quando o servidor é reiniciado a tampdb é recriada, sendo assim podemos pegar a data de criação da DB tempdb */
SELECT * FROM sys.databases WHERE database_id = 2