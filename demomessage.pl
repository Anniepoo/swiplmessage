

i_throw :-
	X is 1 / 0.


% :- multifile user:message_hook/3.

/*
user:message_hook(Term, Kind, Lines) :-
	format('Term: ~w~nKind: ~w~nLines: ~w~n', [Term, Kind, Lines]).
*/



