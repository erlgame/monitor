-module(monitor_svr).
-behaviour(gen_server).

-export([
	start_link/0,
	say_hello/0
	]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	terminate/2, code_change/3
	]).

-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

say_hello() ->
    io:format("say_hello~n"),
    gen_server:call(?MODULE, hello).

%% callbacks

init([]) ->
    %%io:format("hello monitor~n"),
    %%io:format("Local path~p~n", filename:dirname(code:which(?MODULE))), error
    web_server:start(),
    {ok, []}.

handle_call(hello, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {ok, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

