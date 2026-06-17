:- module(presolved_tic_tac_toe, [extension/3, opposite/2]).

extension(1, 4, 7).
extension(1, 2, 3).
extension(1, 5, 9).
extension(1, 2, 3).
extension(2, 5, 8).
extension(3, 6, 9).
extension(4, 5, 6).
extension(7, 8, 9).

opposite(1,9).
opposite(2,8).
opposite(3,7).
opposite(4,6).
opposite(Loc1, Loc2) :- 
	member(Loc2, [1,2,3,4]),
	opposite(Loc2, Loc1).