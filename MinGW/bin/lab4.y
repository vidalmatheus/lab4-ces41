%{
/* Inclusao de arquivos da biblioteca de C */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Definicao dos atributos dos atomos operadores */

#define 	LT 		    1
#define 	LE 	    	2
#define		GT			3
#define		GE			4
#define		EQ			5
#define		NE			6
#define		MAIS        7
#define		MENOS       8
#define		MULT    	9
#define		DIV   	    10
#define		RESTO   	11

/*   Definicao dos tipos de identificadores   */

#define IDPROG		1
#define IDVAR		2
#define IDFUNC		3
#define IDPROC		4
#define IDGLOB		5
#define IDPRINCIPAL 6

/*  Definicao dos tipos de variaveis   */

#define 	NOTVAR		0
#define 	INTEGER		1
#define 	LOGICAL		2
#define 	FLOAT		3
#define 	CHAR		4

/*   Definicao de outras constantes   */

#define	NCLASSHASH	23
#define	TRUE		1
#define	FALSE		0
#define MAXDIMS		10

/*  Strings para nomes dos tipos de identificadores  */

char *nometipid[7] = {" ", "IDPROG", "IDVAR", "IDFUNC", "IDPROC", "IDGLOB", "IDPRINCIPAL"};

/*  Strings para nomes dos tipos de variaveis  */

char *nometipvar[5] = {"NOTVAR",
	"INTEGER", "LOGICAL", "FLOAT", "CHAR"
};

/*    Declaracoes para a tabela de simbolos     */

typedef struct celsimb celsimb;
typedef celsimb *simbolo;
typedef struct elemlistsimb elemlistsimb;
typedef elemlistsimb *pontelemlistsimb;
typedef elemlistsimb *listsimb;
struct celsimb {
	char *cadeia;
	int tid, tvar, tparam, ndims, dims[MAXDIMS+1], nparams;
	char inic, ref, array, parametro;
    listsimb listparam;
	simbolo escopo, prox;
};

/*  Listas de simbolos  */

struct elemlistsimb {
	simbolo simb;
	pontelemlistsimb prox;
};

/*  Variaveis globais para a tabela de simbolos e analise semantica */

simbolo tabsimb[NCLASSHASH];
simbolo simb;
int tipocorrente;
int nparams_call;
simbolo escopo, escopoGlobal;
listsimb modParams;
listsimb listargs;
int indexada;
int inside;

/*
	Prototipos das funcoes para a tabela de simbolos
    	e analise semantica
 */

void InicTabSimb (void);
void ImprimeTabSimb (void);
simbolo InsereSimb (char *, int, int, simbolo);
int hash (char *);
simbolo ProcuraSimb (char *, simbolo);
void VerificaInicRef (void);
void DeclaracaoRepetida (char *, simbolo escopo);
void TipoInadequado (char *);
void NaoDeclarado (char *, simbolo escopo);
void Incompatibilidade (char *);
void Esperado (char *);
void NaoEsperado (char *);
void addToList(listsimb*, int, int);
void isParamsOk(listsimb, listsimb);

%}

/* Definicao do tipo de yylval e dos atributos dos nao terminais */

%union {
	char cadeia[50];
	int atr, valint;
	float valreal;
	char carac;
	simbolo simb;
	int tipoexpr;
	int nsubscr;
    listsimb listparam;
}

/* Declaracao dos atributos dos tokens e dos nao-terminais */

%type	    <simb>	        Variavel
%type 	    <tipoexpr> 	    Expressao  ExprAux1  ExprAux2
                            ExprAux3   ExprAux4   Termo   Fator
%type 		<nsubscr>		Subscritos ListSubscr
%type       <params>        ListParam
%token		<cadeia>		ID
%token		<carac>		    CTCARAC
%token		<cadeia>		CADEIA
%token		<valint>		CTINT
%token		<valreal>	    CTREAL
%token		OR
%token		AND
%token		NOT
%token		<atr>			OPREL
%token		<atr>			OPAD
%token		<atr>			OPMULT
%token		NEG
%token		ABPAR
%token		FPAR
%token		ABCHAV
%token		FCHAV
%token		ABCOL
%token		FCOL
%token		ABTRIP
%token		FTRIP
%token		VIRG
%token		PVIRG
%token		ATRIB
%token		CARAC
%token		COMANDOS
%token		ENQUANTO
%token		ESCREVER
%token		FALSO
%token		INT
%token		LER
%token		LOGIC
%token		PROGRAMA
%token		REAL
%token		SE
%token      SENAO
%token      VAR
%token      VERDADE
%token      CHAMAR
%token      FUNCAO
%token      PARA
%token      PRINCIPAL
%token      PROCEDIMENTO
%token      REPETIR
%token      RETORNAR
%token		<carac>         INVAL
%%
/* Producoes da gramatica:

	Os terminais sao escritos e, depois de alguns,
	para alguma estetica, ha mudanca de linha       */

Prog			:	{InicTabSimb (); indexada = FALSE;}  PROGRAMA  ID {escopo = escopoGlobal = InsereSimb ("##global", IDGLOB, NOTVAR, NULL);} ABTRIP
                    {printf ("programa %s {{{\n", $3); InsereSimb ($3, IDPROG, NOTVAR,escopo);}
                    Decls ListMod ModPrincipal FTRIP  {printf ("}}}\n");
                    VerificaInicRef ();
                    ImprimeTabSimb ();
                    }
                ;

Decls 		    :
                |   VAR  ABCHAV  {printf ("var {\n");}  ListDecl
                    FCHAV  {printf ("}\n");}
                ;

ListDecl		:	Declaracao  |  ListDecl  Declaracao
                ;

Declaracao 	    :	Tipo  ABPAR  {printf ("( ");}  ListElem
                    FPAR  {printf (")\n");}
                ;

Tipo			: 	INT  {printf ("int "); tipocorrente = INTEGER;}
                |   REAL  {printf ("real "); tipocorrente = FLOAT;}
                |   CARAC  {printf ("carac "); tipocorrente = CHAR;}
                |   LOGIC  {printf ("logic "); tipocorrente = LOGICAL;}
                ;

ListElem    	:	Elem  |  ListElem  VIRG  {printf (", ");}  Elem
                ;

Elem        	:	ID  {
                        printf ("%s ", $1);
                        if  (ProcuraSimb ($1, escopo)  !=  NULL)
                            DeclaracaoRepetida ($1,escopo);
                        else
                            simb = InsereSimb ($1,  IDVAR,  tipocorrente, escopo);
							simb->array = FALSE; simb->ndims = 0;
                    }  Dims
                ;

Dims            :
                |   ABCOL  {printf ("[ ");}  ListDim
                    FCOL  {
						printf ("] ");
						simb->array = TRUE;
					}
                ;

ListDim	        : 	CTINT   {printf ("%d ", $1);
							 if ($1 <= 0) Esperado("Valor inteiro positivo");
							 simb->ndims++;
							 if(simb->ndims > MAXDIMS) Incompatibilidade ("Ultrapassou o maximo de dimensoes");
							 simb->dims[simb->ndims] = $1;
							}
                |   ListDim   VIRG   CTINT   {printf (", %d ", $3);
											  if($3 <= 0) Esperado("Valor inteiro positivo");
											  simb->ndims++;
												if(simb->ndims > MAXDIMS) Incompatibilidade ("Ultrapassou o maximo de dimensoes");
											  simb->dims[simb->ndims] = $3;
											 }
                ;

ListMod 	    :
                |   ListMod  Modulo
                ;

Modulo        	:	Cabecalho  Corpo {escopo = escopo->escopo;}
                ;

Cabecalho     	:   CabFunc
                |   CabProc
                ;

CabFunc	    	:   FUNCAO {printf ("funcao ");} Tipo
                    ID
                    {
                        printf ("%s ", $4);
                        if ($4 == "principal")
                            NaoEsperado("Outro modulo de cabecalho principal");
                        else if  (ProcuraSimb ($4, escopo)  !=  NULL)
                            DeclaracaoRepetida ($4, escopo);
                        else
                            escopo = InsereSimb ($4,  IDFUNC,  tipocorrente, escopo);
                    }  ABPAR  {printf ("( ");}  ListParam
                    FPAR  {printf (") ");}
                ;

CabProc	    	:   PROCEDIMENTO {printf ("procedimento ");}
                    ID
                    {
                        printf ("%s ", $3);
                        if ($3 == "principal")
                            NaoEsperado("Outro modulo de cabecalho principal");
                        else if  (ProcuraSimb ($3, escopo)  !=  NULL)
                            DeclaracaoRepetida ($3, escopo);
                        else
                            escopo = InsereSimb ($3,  IDPROC,  tipocorrente, escopo);
                    }  ABPAR  {printf ("( ");}  ListParam
                    FPAR  {printf (")\n");}
                ;

ListParam   	: 	Parametro
                |   ListParam  VIRG {printf (", ");} Parametro

Parametro   	:
				|	Tipo
                    ID  {
                        printf ("%s ", $2);
                        simb = ProcuraSimb ($2, escopo->escopo);
                        if (simb != NULL && simb->tid != IDVAR)
                            NaoEsperado("Chamada de modulo externo como parametro");
                        if  (ProcuraSimb ($2, escopo)  !=  NULL)
                            DeclaracaoRepetida ($2, escopo);
                        else{
                            simb = InsereSimb ($2,  IDVAR,  tipocorrente, escopo);
                            simb->inic = TRUE;
                            simb->ref = TRUE;
                            addToList(&escopo->listparam,simb->tvar,simb->tid);
                        }
                    }
                ;
Corpo     	    :   Decls  Comandos
                ;
ModPrincipal  	:   PRINCIPAL {escopo = InsereSimb ("##principal", IDPRINCIPAL, tipocorrente, escopoGlobal);} {printf ("principal\n");}  Corpo
                ;
Comandos       	:   COMANDOS  {printf ("comandos ");}  CmdComp
                ;
CmdComp 		:   ABCHAV  {printf ("{\n");}  ListCmd  FCHAV
                    {printf ("}\n");}
                ;
ListCmd 		:
                |   ListCmd  Comando
                ;
Comando        	:   CmdComp  |  CmdSe  |  CmdEnquanto
                |   CmdRepetir  |  CmdPara
                |   CmdLer  |  CmdEscrever  |  CmdAtrib
                |   ChamadaProc  |  CmdRetornar  |  PVIRG  {printf ("; ");}
                ;
CmdSe		    :   SE    ABPAR  {printf ("se ( ");}  Expressao  {
                        if ($4 != LOGICAL)
                            Incompatibilidade ("Expressao nao logica em comando se");
                    }  FPAR  {printf (")\n");}  Comando  CmdSenao
                ;
CmdSenao		:
                |   SENAO  {printf ("senao\n");}  Comando
                ;
CmdEnquanto   	:	ENQUANTO  ABPAR  {printf ("enquanto ( ");}  Expressao	{
                        if ($4 != LOGICAL)
                            Incompatibilidade ("Expressao nao logica em comando enquanto");
                    }  FPAR  {printf (")\n");}  Comando
                ;
CmdRepetir  	:   REPETIR {printf ("repetir ");} Comando
                    ENQUANTO  ABPAR {printf ("enquanto ( ");}  Expressao  {
                        if ($7 != LOGICAL)
                            Incompatibilidade ("Expressao nao logica em comando enquanto");
                    }
				    FPAR  PVIRG {printf (") ;\n");}
                ;
CmdPara	    	:   PARA  {printf ("para ");}  Variavel
                    {
                        if  ($3 != NULL){
                            $3->inic = $3->ref = TRUE;
                            if ($3->tvar != INTEGER && $3->tvar != CHAR)
                                Esperado ("Valor interiro ou caractere");
                        }
                    }
                    ABPAR {printf ("( ");} ExprAux4
                    {
                        if ($7 != INTEGER && $7 != CHAR)
                            Incompatibilidade ("Expressao do tipo nao inteira e nao caractere em comando para");
                    }
                    PVIRG {printf ("; ");} Expressao
                    {
                        if ($11 != LOGICAL)
                            Incompatibilidade ("Expressao do tipo nao logica em comando para");
                    }  PVIRG {printf ("; ");} ExprAux4
                    {
                        if ($15 != INTEGER && $15 != CHAR)
                            Incompatibilidade ("Expressao do tipo nao inteira e nao caractere em comando para");
                    }  FPAR {printf (") ");} Comando
                ;
CmdLer   	    :   LER  ABPAR  {printf ("ler ( ");}  ListLeit  FPAR  PVIRG
                    {printf (") ;\n");}
                ;
ListLeit		:   Variavel {if  ($1 != NULL) $1->inic = $1->ref = TRUE;}
				|  ListLeit  VIRG  {printf (", ");}  Variavel Variavel  {if  ($4 != NULL) $4->inic = $4->ref = TRUE;}
                ;
CmdEscrever   	:	ESCREVER  ABPAR  {printf ("escrever ( ");}  ListEscr  FPAR
                    PVIRG  {printf (") ;\n");}
                ;
ListEscr		:	ElemEscr
				|  ListEscr  VIRG  {printf (", ");}  ElemEscr
                ;
ElemEscr		:   CADEIA  {printf ("\"%s\" ", $1);}
				|  Expressao
                ;
ChamadaProc   	:	CHAMAR  ID {printf ("chamar %s ", $2);}
                    {
                        modParams = NULL;
                        if (strcmp($2,escopo->cadeia) == 0)
                            NaoEsperado("Recursao nao e possivel nesta linguagem");
                        simb = ProcuraSimb ($2, escopoGlobal);
                        if (simb == NULL)   NaoDeclarado ($2, escopo);
                        else if (simb->tid != IDPROC)   TipoInadequado ($2);
                        else modParams = simb->listparam;
                        $<simb>$ = simb;
                    }
                    ABPAR  {printf ("(");} Argumentos
                    FPAR  PVIRG  {printf (") ;\n");}
                ;
Argumentos    	:  {listargs = NULL;}                 
                {
                    if (escopo != NULL && modParams != NULL)
                        isParamsOk(listargs,modParams);
                }
                |  {listargs = NULL;} ListExpr
                {
                    if (escopo != NULL && modParams != NULL)
                        isParamsOk(listargs, modParams);
                }
                ;
CmdRetornar  	:	RETORNAR  PVIRG {printf ("retornar ; ");}
                {
                    if (escopo->tid == IDFUNC)
                        Esperado("Retorno de variavel para funcao");
                }
				|   RETORNAR  {printf ("retornar ");}
                    Expressao
                    {
                        if (escopo->tid == IDPROC)
                            NaoEsperado("Retorno de variavel para procedimento");
                        if (escopo->tvar != $3 && ($3 >= 1 && $3 <= 4))
                            Incompatibilidade("Tipo de valor retornado");
                    }  PVIRG  {printf (";\n");}
                ;

CmdAtrib      	:   Variavel  {if  ($1 != NULL) $1->inic = $1->ref = TRUE;}
                    ATRIB  {printf ("= ");}  Expressao  PVIRG
                    {
                        printf (";\n");
                        if ($1 != NULL){
                            if ((($1->tvar == INTEGER || $1->tvar == CHAR) &&
                                ($5 == FLOAT || $5 == LOGICAL)) ||
                                ($1->tvar == FLOAT && $5 == LOGICAL) ||
                                ($1->tvar == LOGICAL && $5 != LOGICAL))
                                Incompatibilidade ("Lado direito de comando de atribuicao improprio");
                        }
                    }
                ;
ListExpr		:  	Expressao
                |   ListExpr  VIRG  {printf (", ");}  Expressao
                ;
Expressao     	:   ExprAux1
				|   Expressao  OR  {printf ("|| ");}  ExprAux1  {
                        if ($1 != LOGICAL || $4 != LOGICAL)
                            Incompatibilidade ("Operando improprio para operador or");
                        $$ = LOGICAL;
                    }
                ;
ExprAux1    	:   ExprAux2
				|   ExprAux1  AND  {printf ("&& ");}  ExprAux2  {
                        if ($1 != LOGICAL || $4 != LOGICAL)
                            Incompatibilidade ("Operando improprio para operador and");
                        $$ = LOGICAL;
                    }
                ;
ExprAux2    	:   ExprAux3
				|   NOT  {printf ("! ");}  ExprAux3  {
                        if ($3 != LOGICAL)
                            Incompatibilidade ("Operando improprio para operador not");
                        $$ = LOGICAL;
                    }
                ;
ExprAux3    	:   ExprAux4
                |   ExprAux4  OPREL  {
                        switch ($2) {
                            case LT: printf ("< "); break;
                            case LE: printf ("<= "); break;
                            case EQ: printf ("== "); break;
                            case NE: printf ("!= "); break;
                            case GT: printf ("> "); break;
                            case GE: printf (">= "); break;
                        }
                    }  ExprAux4  {
                        switch ($2) {
                            case LT: case LE: case GT: case GE:
                                if ($1 != INTEGER && $1 != FLOAT && $1 != CHAR || $4 != INTEGER && $4 != FLOAT && $4 != CHAR)
                                    Incompatibilidade	("Operando improprio para operador relacional");
                                break;
                            case EQ: case NE:
                                if (($1 == LOGICAL || $4 == LOGICAL) && $1 != $4)
                                    Incompatibilidade ("Operando improprio para operador relacional");
                                break;
                        }
                        $$ = LOGICAL;
                    }
                ;
ExprAux4    	:   Termo
                |   ExprAux4  OPAD  {
                        switch ($2) {
                            case MAIS: printf ("+ "); break;
                            case MENOS: printf ("- "); break;
                        }
                    }  Termo  {
                        if ($1 != INTEGER && $1 != FLOAT && $1 != CHAR || $4 != INTEGER && $4!=FLOAT && $4!=CHAR)
                            Incompatibilidade ("Operando improprio para operador aritmetico");
                        if ($1 == FLOAT || $4 == FLOAT) $$ = FLOAT;
                        else $$ = INTEGER;
                    }
                ;
Termo  	    	:   Fator
                |   Termo  OPMULT  {
                        switch ($2) {
                            case MULT: printf ("* "); break;
                            case DIV: printf ("/ "); break;
                            case RESTO: printf ("%% "); break;
                        }
                    }  Fator  {
                        switch ($2) {
                            case MULT: case DIV:
                                if ($1 != INTEGER && $1 != FLOAT && $1 != CHAR
                                    || $4 != INTEGER && $4!=FLOAT && $4!=CHAR)
                                    Incompatibilidade ("Operando improprio para operador aritmetico");
                                if ($1 == FLOAT || $4 == FLOAT) $$ = FLOAT;
                                else $$ = INTEGER;
                                break;
                            case RESTO:
                                if ($1 != INTEGER && $1 != CHAR
                                    ||  $4 != INTEGER && $4 != CHAR)
                                    Incompatibilidade ("Operando improprio para operador resto");
                                $$ = INTEGER;
                                break;
                        }
                    }
                ;
Fator		    :   Variavel  {
                        if  ($1 != NULL) {
                            $1->ref  =  TRUE;
                            $$ = $1->tvar;
                        }
                    }
                |   CTINT  {printf ("%d ", $1); $$ = INTEGER;
 							    if(indexada == TRUE && $1 <= 0){
                                    Esperado("Valor inteiro positivo");
                                }
                            }
                |   CTREAL  {printf ("%g ", $1); $$ = FLOAT;}
                |   CTCARAC  {printf ("\'%c\' ", $1); $$ = CHAR;}
            	|   VERDADE  {printf ("verdade "); $$ = LOGICAL;}
            	|   FALSO  {printf ("falso "); $$ = LOGICAL;}
            	|   NEG  {printf ("~ ");}  Fator  {
                        if ($3 != INTEGER &&
                            $3 != FLOAT && $3 != CHAR)
                            Incompatibilidade  ("Operando improprio para menos unario");
                            if ($3 == FLOAT) $$ = FLOAT;
                            else $$ = INTEGER;
                    }
            	|   ABPAR  {printf ("( ");}  Expressao  FPAR
                    {printf (") "); $$ = $3;}
                |   ChamadaFunc
                ;

Variavel		:   ID  {
                        printf ("%s ", $1);
                        simb = ProcuraSimb ($1, escopo);
                        if (simb == NULL){
                            simb = ProcuraSimb ($1, escopoGlobal);
                            if (simb == NULL){
                                NaoDeclarado ($1, escopo);
                                NaoDeclarado ($1, escopoGlobal);
                                addToList(&listargs,0,IDVAR);
                            }
                            else addToList(&listargs,simb->tvar,simb->tid);
                        }   
                        else if (simb->tid != IDVAR)   TipoInadequado ($1);
                        $<simb>$ = simb;
                        if (simb != NULL && simb->tid == IDVAR)
                            addToList(&listargs,simb->tvar,simb->tid);
                    }
					Subscritos  {
						$$ = $<simb>2;
                        if ($$!= NULL) {
                            if ($$->array == FALSE && $3 > 0)
                                NaoEsperado ("Subscrito\(s)");
                            else if ($$->array == TRUE && $3 == 0)
                                Esperado ("Subscrito\(s)");
                            else if ($$->ndims != $3)
                                Incompatibilidade ("Numero de subscritos incompativel com declaracao");
                        }
					}
                ;
Subscritos      :	{$$ = 0;}
                |   ABCOL  {printf ("[ "); indexada = TRUE;}  ListSubscr
                    FCOL  {
						printf ("] ");
						indexada = FALSE;
						$$ = $3;
					}
                ;
ListSubscr  	:   ExprAux4
					{
						if ($1 != INTEGER && $1 != CHAR)
							Incompatibilidade ("Tipo inadequado para subscrito");
						$$ = 1;
					}
                |   ListSubscr  VIRG  {printf (", ");}  ExprAux4
					{
						if ($4 != INTEGER && $4 != CHAR)
							Incompatibilidade ("Tipo inadequado para subscrito");
						$$ = $1 + 1;
						if($$ > MAXDIMS)
							Incompatibilidade ("Ultrapassou o maximo de dimensoes");
					}
                ;
ChamadaFunc     :   ID  {
                        modParams = NULL;
                        printf ("%s ", $1);
                        if (strcmp($1,escopo->cadeia) == 0)
                            NaoEsperado("Recursao nao e possivel nesta linguagem");
                        simb = ProcuraSimb ($1, escopoGlobal);
                        if (simb == NULL)   NaoDeclarado ($1, escopo);
                        else if (simb->tid != IDFUNC)   TipoInadequado ($1);
                        else modParams = simb->listparam;
                        $<simb>$ = simb;
                    }  ABPAR  {printf ("(");} Argumentos FPAR  {printf (") ");}
%%

/* Inclusao do analisador lexico  */

#include "lex.yy.c"

/*  InicTabSimb: Inicializa a tabela de simbolos   */

void InicTabSimb () {
	int i;
	for (i = 0; i < NCLASSHASH; i++)
		tabsimb[i] = NULL;
}

/*
	ProcuraSimb (cadeia): Procura cadeia na tabela de simbolos;
	Caso ela ali esteja, retorna um ponteiro para sua celula;
	Caso contrario, retorna NULL.
 */

simbolo ProcuraSimb (char *cadeia, simbolo escopo) {
	simbolo s; int i;
	i = hash (cadeia);
	for (s = tabsimb[i]; (s!=NULL);s = s->prox){
        if (strcmp(cadeia, s->cadeia) == 0 && s->escopo == escopo)
            return s;
    }
    return NULL;
}

/*
	InsereSimb (cadeia, tid, tvar): Insere cadeia na tabela de
	simbolos, com tid como tipo de identificador e com tvar como
	tipo de variavel; Retorna um ponteiro para a celula inserida
 */

simbolo InsereSimb (char *cadeia, int tid, int tvar, simbolo escopo) {
	int i; simbolo aux, s;
	i = hash (cadeia); aux = tabsimb[i];
	s = tabsimb[i] = (simbolo) malloc (sizeof (celsimb));
	s->cadeia = (char*) malloc ((strlen(cadeia)+1) * sizeof(char));
	strcpy (s->cadeia, cadeia);
    s->ndims = 0;
    s->listparam = NULL;
	s->tid = tid;		s->tvar = tvar;
	s->inic = FALSE;	s->ref = FALSE;
	s->prox = aux;	    s->escopo = escopo;
    return s;
}

/*
	hash (cadeia): funcao que determina e retorna a classe
	de cadeia na tabela de simbolos implementada por hashing
 */

int hash (char *cadeia) {
	int i, h;
	for (h = i = 0; cadeia[i]; i++) {h += cadeia[i];}
	h = h % NCLASSHASH;
	return h;
}

/* ImprimeTabSimb: Imprime todo o conteudo da tabela de simbolos  */

void ImprimeTabSimb () {
	int i; simbolo s;
	printf ("\n\n   TABELA  DE  SIMBOLOS:\n\n");
	for (i = 0; i < NCLASSHASH; i++)
		if (tabsimb[i]) {
			printf ("Classe %d:\n", i);
			for (s = tabsimb[i]; s!=NULL; s = s->prox){
				printf ("  (%s, %s", s->cadeia,  nometipid[s->tid]);
				if (s->tid == IDVAR) {
					printf (", %s, %d, %d",
						nometipvar[s->tvar], s->inic, s->ref);
                    if (s->array == TRUE) {
                        int j;
                        printf (", EH ARRAY\n\tndims = %d, dimensoes:", s->ndims);
						for (j = 1; j <= s->ndims; j++)
                            printf ("  %d", s->dims[j]);
					}
                }

				if (s->tid == IDFUNC){
					printf(", %s", nometipvar[s->tvar]);
				}
				if (s->escopo != NULL){
					printf(", %s)\n", s->escopo->cadeia);
				}
				else printf(")\n");
			}
		}
}


void VerificaInicRef () {
	int i; simbolo s;

	printf ("\n");
	for (i = 0; i < NCLASSHASH; i++)
		if (tabsimb[i])
			for (s = tabsimb[i]; s!=NULL; s = s->prox)
				if (s->tid == IDVAR) {
					if (s->inic == FALSE)
						printf ("[%12s] %10s:   Nao Inicializada\n", s->escopo->cadeia, s->cadeia);
					if (s->ref == FALSE)
						printf ("[%12s] %10s:   Nao Referenciada\n", s->escopo->cadeia, s->cadeia);
				}
}


/*  Mensagens de erros semanticos  */

void DeclaracaoRepetida (char *s, simbolo escopo) {
	printf ("\n\n***** Declaracao Repetida: %s no escopo: %s*****\n\n", s, escopo->cadeia);
}

void NaoDeclarado (char *s, simbolo escopo) {
    printf ("\n\n***** Identificador Nao Declarado: %s no escopo: %s *****\n\n", s, escopo->cadeia);
}

void TipoInadequado (char *s) {
    printf ("\n\n***** Identificador de Tipo Inadequado: %s *****\n\n", s);
}

void Incompatibilidade (char *s) {
    printf ("\n\n***** Incompatibilidade: %s *****\n\n", s);
}

void Esperado (char *s) {
    printf ("\n\n***** Esperado: %s *****\n\n", s);
}

void NaoEsperado (char *s) {
	printf ("\n\n***** Nao Esperado: %s *****\n\n", s);
}

void addToList(listsimb* lista, int tvar, int tid){
    if (*lista == NULL){
        *lista = (listsimb) malloc (sizeof (elemlistsimb));
        (*lista)->simb = (simbolo) NULL;
        (*lista)->simb = (simbolo) malloc (sizeof (celsimb));
        (*lista)->simb->tvar = tvar;
        (*lista)->simb->tid = tid;
        (*lista)->prox = NULL;
    }
    else {
        (*lista)->prox = (listsimb) malloc (sizeof (elemlistsimb));
        (*lista)->prox->simb = (simbolo) malloc (sizeof (celsimb));
        (*lista)->prox->simb->tvar = tvar;
        (*lista)->prox->simb->tid = tid;
        (*lista)->prox->prox = NULL;
    }
}

void isParamsOk(listsimb listargs, listsimb listparam){
    listsimb a = NULL;
    listsimb p = NULL;

    for (a=listargs,p=listparam; a!=NULL && p!=NULL; a=a->prox, p=p->prox){
        if (a->simb->tvar != p->simb->tvar){
            Incompatibilidade("Tipo do argumento e tipo do parmetro");
            break;
        }
    }
    if ((a && !p) || (!a && p))
        Incompatibilidade("Quantidade de argumentos e de parametros");
}
