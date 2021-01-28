%--------------------------------- - - - - - - - - - -  -  -  -  -   -
% SIST. REPR. CONHECIMENTO E RACIOCINIO - MiEI - 3º ANO LICENCIATURA

%--------------------------------- - - - - - - - - - -  -  -  -  -   -

%PROJETO AVALIAÇÃO INDIVIDUAL (RECURSO)

%AUTOR: Eduardo Lourenço da Conceição
%NÚMERO MECANOGRÁFICO: A83870

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
% SICStus PROLOG: Declaracoes iniciais

:- set_prolog_flag( discontiguous_warnings,off ).
:- set_prolog_flag( single_var_warnings,off ).
:- set_prolog_flag( unknown,fail ).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -

%Consulta ao ficheiro produzido pelo programa "ReadCidades.java"
:-consult('output/cidades.pl').

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Predicados auxiliares

%Uma cidade A é adjacente a B se existir a aresta A->B ou B->A
adjacente(Nodo, ProxNodo) :-
	aresta(Nodo, ProxNodo, _);
	aresta(ProxNodo, Nodo, _).

%Converter uma lista de IDs numa lista de Nomes
ids_to_cities([Head],[Nome]):-cidade(Head,Nome,_,_,_,_,_,_).
ids_to_cities([Head|Tail], [Nome|OT]):-
	cidade(Head, Nome,_,_,_,_,_,_),
	ids_to_cities(Tail, OT).

%Converter um ID num nome
id_to_city(ID,Nome):-cidade(ID, Nome,_,_,_,_,_,_).

%Converter os nomes Input em IDs
cities_to_ids(NomeA, NomeB, IDA, IDB):-
	cidade(IDA,NomeA,_,_,_,_,_,_), cidade(IDB, NomeB,_,_,_,_,_,_).

%Número de ligações de uma cidade
number_arestas_cidade(ID, S):-
	findall(ID, aresta(ID,_,_), S1),
	length(S1, S).

%Fazer uma lista com o número de arestas de cada cidade de uma lista
lst_freqs([In],[(In,Out)]):-
	number_arestas_cidade(In, Out).
lst_freqs([In|T1], [(In,Out)|T2]):-
	number_arestas_cidade(In,Out),
	lst_freqs(T1, T2).

%Calcular o maior valor de uma lista de pares com base no segundo elemento do par
max_lst([(I,X)],(I,X)) :- !, true.
max_lst([(I,X)|Xs], (Id,M)):-
	max_lst(Xs, (Id,M)), M >= X.
max_lst([(Idx,X)|Xs], (Idx,X)):-
	max_lst(Xs, (Id,M)), X >  M.

%Devolver uma lista das cidades de um distrito
cids_dist(Dist, S):-
	distrito(Dist, List),
	ids_to_cities(List, S).

%Verificar se um elemento é cabeça de lista
head([],-1).
head([X|T],X).

%Extensão do Meta Predicado Não
nao(Questao) :- Questao, !, fail.
nao(Questao).

%Extensão do Predicado Concat, que concatena duas listas
concat([],L,L).
concat([H|T],L,[H|Z]):- concat(T,L,Z).

%Auxiliar que inverte uma lista
my_reverse([],[]).
my_reverse([H|T],L) :- my_reverse(T, L2), concat(L2, [H], L).

%Calcular a distância em linha reta entre dois pontos
distancia(X1, Y1, X2, Y2, Result):-
	Psi1 is X1 * 3.1415926535/180,
	Psi2 is X2 * 3.1415926535/180,
	Delta_psi is (X2 - X1) * 3.1415926535/180,
	Delta_lambda is (Y2 - Y1) * 3.1415926535/180,

	A is sin(Delta_psi/2) * sin(Delta_psi/2) * cos(Psi1) * cos(Psi2) * sin(Delta_lambda/2) * sin(Delta_lambda/2),
	C is 2 * atan2(sqrt(A), sqrt(1-A)),

	Result is C * 6371000.

%Calcular a distância em linha reta entre duas cidades
distancia_cids(A, B, D):-
	cidade(A,_,X1,Y1,_,_,_,_),
	cidade(B,_,X2,Y2,_,_,_,_),
	distancia(X1,Y1,X2,Y2,D).

%Calcular a heuristica entre duas cidades (se elas estiverem ligadas, então é 0)
distancia_cids_h(A, B, 0):-
	(aresta(A,B,_);aresta(B,A,_)).
distancia_cids_h(A,B,H):-
	distancia_cids(A,B,H).

%Verificar se a primeira lista está contida na segunda
lst_contains([],Haystack).
lst_contains([Needle],Haystack):-
	member(Needle,Haystack).
lst_contains([Needle|TN], Haystack):-
	member(Needle,Haystack),
	lst_contains(TN,Haystack).



%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 1: "Calcular um trajeto possível entre duas cidades" - DONE

%Utilizando DEPTH-FIRST

resolve_q1_df(Inicio, Fim, N) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	q1_depth_first(IDA, [IDB], S),
	ids_to_cities(S, N).

q1_depth_first(Inicio, [Inicio|T], [Inicio|T]).
q1_depth_first(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	q1_depth_first(Inicio, [Candidato, Ar|T], Caminho).

%Utilizando BREADTH-FIRST

resolve_q1_bf(Inicio, Fim, N) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	q1_breadth_first(IDA, IDB, [[IDA]], S),
	my_reverse(S,S2),
	ids_to_cities(S2, N).

q1_breadth_first(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):-
	head([Candidato|T], Fim).
q1_breadth_first(Inicio, Fim, [CaminhoCandidato|T], S):-
	add_candidatos(CaminhoCandidato, N),
	append(T, N, Prox),
	q1_breadth_first(Inicio, Fim, Prox, S).

add_candidatos([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
					(adjacente(ProxCandidato, Candidato), \+ member(ProxCandidato, [Candidato|T])),
					NovosCandidatos),!.
add_candidatos(T, []).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 2: "Selecionar apenas cidades, com uma determinada caraterística, para um determinado trajeto"

%Utilizando DEPTH-FIRST

resolve_q2_df(Inicio, Fim, N, I) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	%Para um determinado percurso, passar apenas por cidades que sejam Património da UNESCO
	%É possível que não hajam percursos possíveis com esta característica
	(I == 1,
	q2_depth_first_patrim(IDA, [IDB], S);
	%Para um determinado percurso, passar apenas por cidades que sejam possíveis candidatos para Património da UNESCO
	I == 2,
	q2_depth_first_nom(IDA, [IDB], S)),
	ids_to_cities(S, N).

q2_depth_first_patrim(Inicio, [Inicio|T], [Inicio|T]).
q2_depth_first_patrim(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	cidade(Candidato, _, _, _, _, _, 1, _),
	q2_depth_first_patrim(Inicio, [Candidato, Ar|T], Caminho).

q2_depth_first_nom(Inicio, [Inicio|T], [Inicio|T]).
q2_depth_first_nom(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	cidade(Candidato, _, _, _, _, _, _, 1),
	q2_depth_first_patrim(Inicio, [Candidato, Ar|T], Caminho).

%Utilizando BREADTH-FIRST

resolve_q2_bf(Inicio, Fim, N, I) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	(I == 1,
	q2_breadth_first_patrim(IDA, IDB, [[IDA]], S);
	I == 2,
	q2_breadth_first_nome(IDA, IDB, [[IDA]], S)),
	my_reverse(S,S2),
	ids_to_cities(S2, N).

q1_breadth_first_patrim(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):-
	head([Candidato|T], Fim).
q1_breadth_first_patrim(Inicio, Fim, [CaminhoCandidato|T], S):-
	add_candidatos_patrim(CaminhoCandidato, N),
	append(T, N, Prox),
	q1_breadth_first_patrim(Inicio, Fim, Prox, S).

add_candidatos_patrim([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
					(adjacente(ProxCandidato, Candidato), cidade(ProxCandidato, _, _, _, _, _, 1, _),\+ member(ProxCandidato, [Candidato|T])),
					NovosCandidatos),!.
add_candidatos_patrim(T, []).

q1_breadth_first_nome(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):-
	head([Candidato|T], Fim).
q1_breadth_first_nome(Inicio, Fim, [CaminhoCandidato|T], S):-
	add_candidatos_nome(CaminhoCandidato, N),
	append(T, N, Prox),
	q1_breadth_first_nome(Inicio, Fim, Prox, S).

add_candidatos_nome([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
					(adjacente(ProxCandidato, Candidato), cidade(ProxCandidato, _, _, _, _, _, _, 1),\+ member(ProxCandidato, [Candidato|T])),
					NovosCandidatos),!.
add_candidatos_nome(T, []).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 3: "Excluir uma ou mais caracteristicas de cidades para um percurso"

%Utilizando DEPTH-FIRST
resolve_q3_df(Inicio, Fim, N, I) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	%Excluir cidades que sejam Património da UNESCO
	(I == 1,
	q3_depth_first_patrim(IDA, [IDB], S);
	%Excluir cidades que sejam Candidatos
	I == 2,
	q3_depth_first_nome(IDA, [IDB], S);
	%Excluir cidades que sejam Património da UNESCO e Candidatos
	I == 3,
	q3_depth_first_none(IDA, [IDB], S)),
	ids_to_cities(S, N).

q3_depth_first_patrim(Inicio, [Inicio|T], [Inicio|T]).
q3_depth_first_patrim(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	cidade(Candidato, _, _, _, _, _, 0, _),
	q3_depth_first_patrim(Inicio, [Candidato, Ar|T], Caminho).

q3_depth_first_nome(Inicio, [Inicio|T], [Inicio|T]).
q3_depth_first_nome(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	cidade(Candidato, _, _, _, _, _, _, 0),
	q3_depth_first_patrim(Inicio, [Candidato, Ar|T], Caminho).

q3_depth_first_none(Inicio, [Inicio|T], [Inicio|T]).
q3_depth_first_none(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	cidade(Candidato, _, _, _, _, _, 0, 0),
	q3_depth_first_none(Inicio, [Candidato, Ar|T], Caminho).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 4: "Identificar num determinado percurso qual a cidade com o maior número de ligações"

%Este predicado aceita uma lista de IDs, como tal, pode ser aplicado a qualquer uma das queries
mais_arestas(S, (Nome, Arestas)):-
	lst_freqs(S, F),
	max_lst(F,(Id,Arestas)),
	id_to_city(Id,Nome).

%Para demonstrar, apliquemos a DF do primeiro exercício
resolve_q4_df(Inicio, Fim, Maior):-
	cities_to_ids(Inicio, Fim, A, B),
	q1_depth_first(A, [B], S),
	mais_arestas(S, Maior).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 5: "Escolher o menor percurso (usando o critério do menor número de cidades percorridas)"
%Utilizando BREADTH-FIRST -> dá a resposta logo
resolve_q5_bf(Inicio, Fim, N) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	q1_breadth_first(IDA, IDB, [[IDA]], S),
	my_reverse(S,S2),
	ids_to_cities(S2, N).

q1_breadth_first(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):-
	head([Candidato|T], Fim).
q1_breadth_first(Inicio, Fim, [CaminhoCandidato|T], S):-
	add_candidatos(CaminhoCandidato, N),
	append(T, N, Prox),
	q1_breadth_first(Inicio, Fim, Prox, S).

add_candidatos([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
					(adjacente(ProxCandidato, Candidato),
					nao(member(ProxCandidato, [Candidato|T]))),
					NovosCandidatos),!.
add_candidatos(T, []).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 6: "Escolher o percurso mais rápido (usando o critério da distância)"

%Utilizando A* -> Apresenta a quirk de poder não ser o overall caminho mais curto,
%porque vai ser utilizada uma heurística que não foi totalmente fine-tuned
resolve_q6_ae(Inicio, Fim, (S,C)):-
	cities_to_ids(Inicio, Fim, A, B),
	distancia_cids_h(A, B, D),
	q6_a_estrela(A, B, [[A]/0/D], S1/C/_),
	my_reverse(S1,S2),
	ids_to_cities(S2,S).

q6_a_estrela(Inicio, Fim, Caminhos, S):-
  shortest_ae(Caminhos, S),
  S = [Candidato|_]/_/_,
  Candidato == Fim.
q6_a_estrela(Inicio, Fim, Caminhos, S):-
  shortest_ae(Caminhos, O),
  add_candidatos_6(Fim, O, CaminhosAux),
  q6_a_estrela(Inicio, Fim, CaminhosAux, S).

shortest_ae([L],L):-!.
shortest_ae([C1/D1/E1, _/D2/E2|T], S):-
  E1+D1 =< E2+D2,!,
  shortest_ae([C1/D1/E1|T], S).
shortest_ae([_|T], S):-
  shortest_ae(T, S).

%Utilizando GREEDY
resolve_q6_greedy(Inicio, Fim, (S,C)):-
	cities_to_ids(Inicio, Fim, A, B),
	distancia_cids_h(A, B, D),
	q6_greedy(A, B, [[A]/0/D], S1/C/_),
	my_reverse(S1,S2),
	ids_to_cities(S2,S).

q6_greedy(Inicio, Fim, Caminhos, S):-
  shortest_greedy(Caminhos, S),
  S = [Candidato|_]/_/_,
  Candidato == Fim.
q6_greedy(Inicio, Fim, Caminhos, S):-
  shortest_greedy(Caminhos, O),
  add_candidatos_6(Fim, O, CaminhosAux),
  q6_greedy(Inicio, Fim, CaminhosAux, S).

shortest_greedy([L],L):-!.
shortest_greedy([C1/D1/E1, _/D2/E2|T], S):-
  E1 =< E2,!,
  shortest_greedy([C1/D1/E1|T], S).
shortest_greedy([_|T], S):-
  shortest_greedy(T, S).



add_candidatos_6(Fim, O, CaminhosAux):-
  findall(N, adjacente_6(Fim, O, N), CaminhosAux).

adjacente_6(Fim, [Nodo|Caminho]/Custo/_, [ProxNodo,Nodo|Caminho]/NovoCusto/Est) :-
	adjacente_dist(Nodo, ProxNodo, PassoCusto),
  \+ member(ProxNodo, Caminho),
	NovoCusto is Custo + PassoCusto,
	distancia_cids_h(ProxNodo, Fim, Est).

adjacente_dist(Nodo, ProxNodo, D):-
	aresta(Nodo,ProxNodo,D).
adjacente_dist(Nodo, ProxNodo, D):-
	aresta(ProxNodo,Nodo,D).
%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 7: "Escolher um percurso que passe apenas por cidades “minor”"

%Utilizando DEPTH-FIRST
resolve_q7_df(Inicio, Fim, N) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	q7_depth_first_minors(IDA, [IDB], S),
	ids_to_cities(S, N).

q7_depth_first_minors(Inicio, [Inicio|T], [Inicio|T]).
q7_depth_first_minors(Inicio, [Ar|T], Caminho):-
	adjacente(Candidato, Ar),
	\+ member(Candidato, [Ar|T]),
	cidade(Candidato, _, _, _, _, 3, _, _),
	q7_depth_first_minors(Inicio, [Candidato, Ar|T], Caminho).

%Utilizando BREADTH-FIRST
resolve_q7_bf(Inicio, Fim, N) :-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	q7_breadth_first(IDA, IDB, [[IDA]], S),
	my_reverse(S,S2),
	ids_to_cities(S2, N).

q7_breadth_first(Inicio, Fim, [[Candidato|T]|_], [Candidato|T]):-
	head([Candidato|T], Fim).
q7_breadth_first(Inicio, Fim, [CaminhoCandidato|T], S):-
	add_candidatos_7(CaminhoCandidato, N),
	append(T, N, Prox),
	q7_breadth_first(Inicio, Fim, Prox, S).

add_candidatos_7([Candidato|T], NovosCandidatos):-
	findall([ProxCandidato, Candidato|T],
					(adjacente(ProxCandidato, Candidato), cidade(ProxCandidato, _, _, _, _, 3, _, _), \+ member(ProxCandidato, [Candidato|T])),
					NovosCandidatos).
add_candidatos_7(T, []).

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
%Questão 8: "Escolher uma ou mais cidades intermédias por onde o percurso deverá obrigatoriamente passar"

%Utilizando o Depth-First
resolve_q8_df(Inicio, Fim, CidadesObrigatorias, S):-
	cities_to_ids(Inicio, Fim, A, B),
	distancia_cids_h(A, B, D),
	q1_depth_first(A, [B], S2),
	ids_to_cities(S2,S),
	lst_contains(CidadesObrigatorias, S).

%Utilizando o Breadth-First
resolve_q8_bf(Inicio, Fim, CidadesObrigatorias, N):-
	cities_to_ids(Inicio, Fim, IDA, IDB),
	q1_breadth_first(IDA, IDB, [[IDA]], S),
	my_reverse(S,S2),
	ids_to_cities(S2, N),
	lst_contains(CidadesObrigatorias, N).
