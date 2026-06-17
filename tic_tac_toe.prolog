:- module(tic_tac_toe, []).

:- use_module('presolved_tic_tac_toe.prolog', [extension/3, opposite/2]).

% :- dynamic(start_parity/1).

start_parity(x).

check_parity(P) :-
	(    member(P, [x,o])
	-> true
	;    throw(error(domain_error(x_or_o, P)))).
	
flip_parity(P1, P2) :-
	ground(P1),
	(    (P1 = x) -> (P2 = o)
	;    (P1 = o) -> (P2 = x)
	).
	
second_parity(P) :- 
    start_parity(PrevP),
	check_parity(PrevP),
	flip_parity(PrevP, P).

parity(Board, P) :-
	start_parity(StartParity),
	second_parity(SecondParity),
	length(Board, Length),
	Mod is Length mod 2,
	((Mod = 0) -> (P = StartParity) ;
	 (Mod = 1) -> (P = SecondParity)
	).
	
validate_board([], _) :- !.
	
validate_board(Board, Parity) :-
	(   (   append(_, [Expression], Board),
	        Expression = '='(PrevParity,_),
		    ((PrevParity = x, Parity = o)
			;(PrevParity = o, Parity = x))
		)
	-> true
	;   throw(error(domain_error(alternating_parity, Board)))
	), !.
	
free([], Location) :- ground(Location), !.

free('='(_,Placed), Location) :-
	ground([Placed, Location]),
	Location \= Placed,
	!.
	
free([H|T], Location) :-
	ground([Location, H, T]),
	free(H, Location),
	free(T, Location).
	
free(Board, Location) :-
	var(Location),
	ground(Board),
	findall(X, between(1,9,X), Range),
	member(Loc, Range),
	free(Board, Loc),
	Location = Loc.
	
rhs('='(_, RHS), RHS).
lhs('='(LHS, _), LHS).
	
placed(Board, Location) :-
	ground(Board),
	maplist(rhs, Board, List),
	member(Location, List).

hypothesis(Board, Parity, Hypothesis, VirtualBoard) :-
	ground(Board),
	ground(Hypothesis),
	parity(Board, Parity),
	append(Board, ['='(Parity,Hypothesis)], VirtualBoard).

engine(Board, Completion) :-
	ground(Board),
	parity(Board, Parity),
	validate_board(Board, Parity),
	validate_board(Board, Parity),
	solution(Board, Parity, Solution),
	hypothesis(Board, Parity, Solution, Completion).

adjacent_space(Loc1, Loc2) :-
	member(Pair, [[1,2],[1,4],[1,5],[2,3],[2,4],[2,5],[2,6],[3,5],[3,6],[4,5],[4,7],[4,8],[5,6],[5,7],[5,8],[5,9],[6,8],[6,9],[7,8],[8,9]]
	),
	Pair = [Loc1, Loc2].
	
parity_loc(Board, Loc, Parity) :-
	ground(Board),
	placed(Board, Loc),
	maplist(lhs, Board, LHSList),
	maplist(rhs, Board, RHSList),
	nth0(Index, RHSList, Loc),
	nth0(Index, LHSList, Parity).

win(Board, Parity, Solution) :- 
	adjacent_space(Loc1, Loc2),
	parity_loc(Board, Loc1, Parity),
	parity_loc(Board, Loc2, Parity),
	extension(Loc1, Loc2, Solution),
	free(Board, Solution), !.
	
block_opponent_win(Board, Parity, Solution) :- 
	adjacent_space(Loc1, Loc2),
	flip_parity(Parity, OpponentParity),
	parity_loc(Board, Loc1, OpponentParity),
	parity_loc(Board, Loc2, OpponentParity),
	extension(Loc1, Loc2, Solution),
	free(Board, Solution), !.
	
forked(Board, Parity) :-
	adjacent_space(Loc1, Loc2),
	parity_loc(Board, Loc1, Parity),
	parity_loc(Board, Loc2, Parity),
	extension(Loc1, Loc2, Loc3),
	free(Board, Loc3),
	adjacent_space(Loc4, Loc5),
	parity_loc(Board, Loc4, Parity),
	parity_loc(Board, Loc5, Parity),
	extension(Loc4, Loc5, Loc6),
	free(Board, Loc6),
	Loc5 \== Loc6.

create_fork(Board, Parity, Solution) :-
	free(Board, Solution),
	hypothesis(Board, Parity, Solution, VirtualBoard),
	forked(VirtualBoard, Parity), !.

mark_center(Board, _, 5) :-
	free(Board, 5), !.

empty_corner(Board, _, Solution) :-
	member(Solution, [1,3,7,9]),
	free(Board, Solution), !.

empty_side(Board, _, Solution) :-
	member(Solution, [2,4,6,8]),
	free(Board, Solution), !.

fallback(Board, _, Solution) :-
	member(Solution, [1,2,3,4,5,6,7,8,9]),
	free(Board, Solution), !.
	
opposite_corner(Board, Parity, Solution) :-
	flip_parity(Parity, OpponentParity),
	member(OpponentLoc, [1,3,7,9]),
	placed(Board, OpponentLoc),
	parity_loc(Board, OpponentLoc, OpponentParity),
	opposite(OpponentLoc, Solution),
	free(Board, Solution), !.

panic(_, _, no_move_possible) :- !.

solution(Board, Parity, Solution) :- win(Board, Parity, Solution), !. % strategy 1
solution(Board, Parity, Solution) :- block_opponent_win(Board, Parity, Solution), !. % strategy 2
solution(Board, Parity, Solution) :- create_fork(Board, Parity, Solution), !. % strategy 3

solution([], _, 7). % strategy 5, game start, assume opponent is not perfect
solution(Board, Parity, Solution) :- 
	mark_center(Board, Parity, Solution), !. % strategy 5, midgame
solution(Board, Parity, Solution) :- 
	opposite_corner(Board, Parity, Solution) % strategy 6
solution(Board, Parity, Solution) :- 
	empty_corner(Board, Parity, Solution), !. % strategy 7
solution(Board, Parity, Solution) :- 
	empty_side(Board, Parity, Solution), !. % strategy 8
solution(Board, Parity, Solution) :- 
	fallback(Board, Parity, Solution), !. % this should not be possible
solution(Board, Parity, Solution) :- 
	panic(Board, Parity, Solution), !. % all moves filled or board weirdly illegal