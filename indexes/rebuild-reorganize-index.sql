/*
	Características:
	- Usa um espaço a mais no disco para realizar a operação (já que cria um novo índice)
	- Altera o LEAF LEVEL, além do root e dos níveis intermediários.
	- Atualiza as estatísticas dos índices
	- Se cancelar o comando, perde tudo o que foi feito.
	- Causa um LOCK grande na tabela quando executado de forma ONLINE.

	Quando usar: Fragmentação maior que 30%.
*/
ALTER INDEX U3_CPF_Sexo ON Cliente REBUILD WITH(FILLFACTOR=90)

/*
	Características:
	- Não utiliza espaço em disco a mais.
	- Reorganiza os LEAF LEVEL dos índices
	- Não atualiza as estatísticas dos índices
	- Se cancelar o comando, não perde o que foi feito.

	Quando usar: Fragmentação entre 10 e 30%.
*/
ALTER INDEX U3_CPF_Sexo ON Cliente REORGANIZE