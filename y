#! /usr/bin/env escript
%% vi: ft=erlang

factorial(0) -> 1;
factorial(N) ->
	N * factorial(N - 1).

almost_factorial() ->
	fun(F) ->
		fun(N) ->
			case N of
				0 -> 1;
				_ -> N * apply(F, [N - 1])
			end
		end
	end.

factorialB(N) ->
	FactorialA = fun(M) -> factorial(M) end,
	apply(apply(almost_factorial(), [FactorialA]), [N]).

factorialC(N) ->
	apply(apply(almost_factorial(), [fun(M) -> factorialC(M) end]), [N]).

identity() ->
	fun(F) -> F end.

factorial0() ->
	apply(almost_factorial(), [identity()]).

factorial1() ->
	apply(almost_factorial(), [factorial0()]).

factorial2() ->
	apply(almost_factorial(), [factorial1()]).

% stack overflow!
y_lazy() ->
	fun(F) ->
		apply(F, [apply(y_lazy(), [F])])
	end.

y_strict() ->
	fun(F) ->
		apply(F, [fun(X) -> apply(apply(y_strict(), [F]), [X]) end])
	end.

factorialY() ->
	apply(y_strict(), [almost_factorial()]).

part_factorial_self() ->
	fun(Self, N) ->
		case N of
			0 -> 1;
			_ -> N * apply(Self, [Self, N - 1])
		end
	end.

self_apply(F) ->
	apply(F, [F]).

part_factorial1() ->
	fun(Self) ->
		fun(N) ->
			case N of
				0 -> 1;
				_ -> N * apply(self_apply(Self), [N - 1])
			end
		end
	end.

part_factorial2() ->
	fun(Self) ->
		F = self_apply(Self),
		fun(N) ->
			case N of
				0 -> 1;
				_ -> N * apply(F, [N - 1])
			end
		end
	end.

factorialP1() ->
	X = fun(Self) ->
		apply(almost_factorial(), self_apply(Self))
	end,
	self_apply(X).

factorialP2() ->
	L1 = fun(X) -> self_apply(X) end,
	L2 = fun(X) ->
		apply(almost_factorial(), self_apply(X))
	end,
	apply(L1, [L2]).

y_combinator_lazy(F) ->
	L1 = fun(X) -> self_apply(X) end,
	L2 = fun(X) ->
		apply(F, self_apply(X))
	end,
	apply(L1, [L2]).

factorial_y_lazy(N) ->
	apply(y_combinator_lazy(almost_factorial()), [N]).

%%% strict y combinator

part_factorial_strict1() ->
	fun(Self) ->
		F = fun(Y) -> apply(self_apply(Self), [Y]) end,
		fun(N) ->
			case N of
				0 -> 1;
				_ -> N * apply(F, [N - 1])
			end
		end
	end.

part_factorial_strict2() ->
	fun(Self) ->
		L1 = fun(F) -> 
			fun(N) ->
				case N of
					0 -> 1;
					_ -> N * apply(F, [N - 1])
				end
			end
		end,
		L2 = fun(Y) -> apply(self_apply(Self), [Y]) end,
		apply(L1, [L2])
	end.

part_factorial_strict3() ->
	fun(Self) ->
		apply(almost_factorial(), [
			fun(Y) -> apply(self_apply(Self), [Y]) end
		])
	end.

factorialP3(N) ->
	PF = fun(Self) ->
		apply(almost_factorial(), [
			fun(Y) -> apply(self_apply(Self), [Y]) end
		])
	end,
	apply(self_apply(PF), [N]).

factorialP4(N) ->
	apply(fun(X) -> apply(self_apply(X), [N]) end, [
		fun(X) ->
			apply(almost_factorial(), [
				fun(Y) -> apply(self_apply(X), [Y]) end
			])
		end
	]).

y_combinator_strict1(F) ->
	L1 = fun(X) -> apply(F, [fun(Y) -> apply(self_apply(X), [Y]) end]) end,
	L2 = fun(X) -> apply(F, [fun(Y) -> apply(self_apply(X), [Y]) end]) end,
	apply(L1, [L2]).

y_combinator_strict2(F) ->
	L1 = fun(X) -> apply(X, [X]) end,
	L2 = fun(X) -> apply(F, [fun(Y) -> apply(self_apply(X), [Y]) end]) end,
	apply(L1, [L2]).

y_fact(N) ->
	apply(y_combinator_strict2(almost_factorial()), [N]).

%%% helpers

call1(F, N) ->
	apply(F, [N]).

call_self(F, N) ->
	apply(F, [F, N]).

pr_fac(N) ->
	%io:format("fac ~w: ~w~n", [ N, call1(factorialY(), N) ]).
	%io:format("fac ~w: ~w~n", [ N, call_self(part_factorial_self(), N) ]).
	%io:format("fac ~w: ~w~n", [ N, call1(self_apply(part_factorial_strict3()), N) ]).
	io:format("fac ~w: ~w~n", [ N, y_fact(N) ]).

main(_) ->
	lists:foreach(fun(F) -> pr_fac(F) end, [0, 1, 2, 6, 8]).
