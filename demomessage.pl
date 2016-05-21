

i_throw :-
	X is 1 / 0.

do_a_message :-
	print_message(information, tacos(yes, yes, yes)).


:- multifile user:message_hook/3.
/*
 * this is stupid and wrong.  this is NOT for translation,
 * it's for doing custom output. It's (+, +, +)
user:message_hook(tacos(Meat, Beans, Cheese), information,
		  ['yummy tacos with',
		  nl,
		  'meat ~w'-[Meat],
		   nl,
		  'beans-~w'-[Beans],
		   nl,
		   'cheese-~w'-[Cheese]]).

*/

/*
user:message_hook(Term, Kind, Lines) :-
	format('Term: ~w~nKind: ~w~nLines: ~w~n', [Term, Kind, Lines]).
*/

:- multifile prolog:message//1.

prolog:message(data_error(SKT, no_name)) -->
	[ 'The skt ~w lacks a human readable name'-[SKT]].
prolog:message(data_error(SKT, no_sku)) -->
	[ 'The skt ~w lacks an atom sku'-[SKT]].
prolog:message(data_error(SKT, no_bom)) -->
	[ 'The skt ~w lacks a bill of materials'-[SKT]].
prolog:message(data_error(SKT, no_price)) -->
	[ 'The skt ~w lacks a price'-[SKT]].
prolog:message(no_such_part(Part)) --> {
	   skt_bom(SKT, BOM),
	   member(Part, BOM)
       },
	[ 'The part ~w is used in ~w (poss. others too) but not defined'-[Part, SKT]].
prolog:message(no_such_part(Part)) -->
	[ 'The part ~w is not defined or used???'-[Part]].
prolog:message(no_part_name(Part)) -->
	[ 'The part ~w lacks a human readable label'-[Part]].
prolog:message(priceless_part(Part)) -->
	[ 'The part ~w lacks a price.'-[Part]].

prolog:message(no_such_vendor(Vendor)) -->
	[ 'No known vendor like ~w'-[Vendor]].
prolog:message(no_vendor_url(Vendor)) -->
	[ 'Vendor ~w lacks a website'-[Vendor]].



print_banner :-
	print_message(debug(make), annies_amazing_thing(7,3,23)).


prolog:message(annies_amazing_thing(Major, Minor, Rev)) -->
	[ 'Annie\'s Amazing Thing!', nl,
	  'Does Something Or Other!', nl,
	  'Rev ~d.~d.~d'-[Major, Minor, Rev],
	  nl].





