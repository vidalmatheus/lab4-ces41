# lab4-ces41

1) CmdPara -> variáveis locais
2) Escopo -> subprogramas
3) vector -> {
	verificação de índices
	inicializar e referenciar ao menos 1 posição
	(Ver inter02.y)
4) Variáveis escalares não podem ter subscritos.
5) Os elementos de uma variável indexada só poderão ser atribuídos ou receber atribuição um de cada vez (ndims da struct)
6) Os elementos de uma variável indexada só poderão ser lidos ou escritos um de cada vez. (não pode ler(vetor) -> ndims da struct)
7) Os tipos dos resultados das diversas classes de expressões (info expressao e infovar -> trocar pra .simb .tipo)
8) Os tipos dos operandos admitidos pelos operadores de expressões (ver operando opnd; em infoexpressão)
9) As expressões nos cabeçalhos de comandos se e enquanto e no encerramento de comandos repetir devem ser relacionais ou lógicas (infoexpressao .tipo)
10) A variável de controle de um comando para deve ser escalar do tipo inteiro ou caractere (CmdPara -> adicionar verificação de tipo)
    A primeira e a terceira expressão do cabeçalho de um comando para devem ser do tipo inteiro ou caractere e a segunda expressão deve ser do tipo lógico. 

11) O programa deve ter um e um só módulo de cabeçalho principal (esperado }}} após principal acabar)
12) O identificador de um comando chamar deve ser do tipo nome de procedimento e o de uma chamada de função numa expressão deve ser do tipo nome de função (IDPROC & IDFUNC)
13) Um identificador de variável e de parâmetro deve ser do tipo nome de variável. (usar IDVAR - em todo código, atentar para os parâmetros)
14) O identificador que dá nome ao programa deve ser do tipo nome de programa. (IDPROG)
15) O número de argumentos na chamada de um módulo deve ser igual ao número de parâmetros do mesmo. (implementar nparmas e nparams_call)
    Deve haver compatibilidade entre um argumento de chamada de um módulo e seu parâmetro correspondente
16) Todo comando retornar dentro de um procedimento não deve ser seguido de expressão e dentro de uma função deve ser seguido por uma expressão (returna; returna exp;)
    Deve haver compatibilidade entre o tipo de uma função e o tipo da expressão de qualquer comando retornar em seu escopo (implementar um tmod na struct de simb - procuraSimb)

17) Módulos não são usados como parâmetros ou argumentos de chamada de outros módulos (olhar o tid)

18) A linguagem não admite recursividade. (if ($<num>->cadeia == $<num>->escopo->cadeia) É recursão!)

How to Run:
flex tsimb012020.l
yacc tsimb012020.y
.\gcc.exe y.tab.c main.c yyerror.c -o tsimb012020 -lfl
Get-Content .\tsimb012020.dat | .\tsimb012020.exe > tsimb012020.txt
