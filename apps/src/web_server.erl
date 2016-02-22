-module(web_server).

-export([start/0, start/1]).

-export([init/3, handle/2, terminate/3]).

%-export([get_playdata/0]).

-define(MEMUSED, "MemUsed").
-define(NETRECV, "NetRecv").
-define(NETSEND, "NetSend").
-define(TIMENOW, "TimeNow").
-define(DEFAULT_LISTEN_PORT, 8080).

start() ->
    {ok, Port} = config:get(listen_port, ?DEFAULT_LISTEN_PORT),
    io:format("Listen Port:~p~n", [Port]),
    start(Port).

start(Port) ->
    N_acceptors = 10,
    Dispatch = cowboy_router:compile([
    	    {'_', [{'_', web_server, []}]}
    	]),
    cowboy:start_http(my_web_server,
    	    N_acceptors,
    	    [{port, Port}],
    	    [{env, [{dispatch, Dispatch}]}]
    	).

init({tcp, http}, Req, _Opts) ->
    {ok, Req, undefined}.

handle(Req, State) ->
    {Path, Req1} = cowboy_req:path(Req),
    handle1(Path, Req1, State).
    % Response = read_file(Path),
    % {ok, Req2} = cowboy_req:reply(200, [], Response, Req1),
    % {ok, Req2, State}.
handle1(<<"/playerinfo">>, Req, State) ->
    {Args, Req1} = cowboy_req:qs_vals(Req),
    [{<<"days">>,Days}] = Args,
    NumDays = list_to_integer(binary_to_list(Days)),
    % io:format("Args:~p NumDays:~p~n", [Args, NumDays]),
    Data1 = get_playdata(NumDays),
    Data2 = Data1 -- ",",
    Json = "[" ++ Data2 ++ "]",
    {ok, Req2} = cowboy_req:reply(200, [], Json, Req1),
    {ok, Req2, State};
handle1(Path, Req, State) ->
    Response = read_file(Path),
    {ok, Req1} = cowboy_req:reply(200, [], Response, Req),
    {ok, Req1, State}.

terminate(_Reason, _Req, _State) ->
    ok.

% read_line(Dev) ->
%     case io:get_line(Dev, '') of
%     	% eof -> "";
%     	% {error, Error} ->
%     	%     io:format("read_line Error:~p~n", [Error]),
%      %        Error;
%     	Data ->
%     		L = string:tokens(Data, " "),
%     	    [_,V|_] = L,
%     	    V
%     end.

get_meminfo() ->
    File = <<"/proc/meminfo">>,
    case file:open(File, read) of
    	{ok, S} -> 
    	    L1 = io:get_line(S, ''),
    	    [_,V1|_] = string:tokens(L1, " "),
    	    {MemTotal,[]} = string:to_integer(V1),
    	    L2 = io:get_line(S, ''),
    	    [_,V2|_] = string:tokens(L2, " "),
    	    {MemFree,[]} = string:to_integer(V2),
    	    L3 = io:get_line(S, ''),
    	    [_,V3|_] = string:tokens(L3, " "),
    	    {MemBuff,[]} = string:to_integer(V3),
    	    L4 = io:get_line(S, ''),
    	    [_,V4|_] = string:tokens(L4, " "),
    	    {MemCach,[]} = string:to_integer(V4),
    	    % [MemTotal,[]] = string:to_integer(read_line(S)),
    	    % [MemFree,[]] = string:to_integer(read_line(S)),
    	    % [MemBuff,[]] = string:to_integer(read_line(S)),
    	    % [MemCach,[]] = string:to_integer(read_line(S)),
    	    file:close(S),
    	    RealUsed = MemTotal - MemFree - MemBuff - MemCach,
    	    %ListVal = erlang:integer_to_list(RealUsed) ++ "kb"
    	    BinVal = erlang:integer_to_binary(RealUsed),
    	    [{<<?MEMUSED>>, BinVal}];

    	_ -> ["<pre>cannot open:", File, "</pre>"]
    end.

recursive_read(Dev, Eth, Res) ->
    case io:get_line(Dev, '') of
    	eof ->
    	    %io:format("To eof, Res:~p~n", [Res]),
    	    Res;
    	Data ->
    	    L = string:tokens(Data, ": "),
    	    %io:format("Data:~p L:~p~n", [Data, L]),
		    [H|_T] = L,
		    case H of
		    	Eth ->
		    	    [_,Recv,_,_,_,_,_,_,_,Send,_,_,_,_,_,_,_] = L,
		    	    %io:format("Recv:~p Send:~p~n", [Recv, Send]),
		    	    {RecvInt,[]} = string:to_integer(Recv),
		    	    {SendInt,[]} = string:to_integer(Send),
		    	    Resplus = Res ++ [{<<?NETRECV>>, erlang:integer_to_binary(RecvInt)}, 
		    	                      {<<?NETSEND>>, erlang:integer_to_binary(SendInt)}],
		    	    recursive_read(Dev, Eth, Resplus);

		    	_ -> recursive_read(Dev, Eth, Res)
		    end
    end.   

get_netinfo(Eth) ->
    File = <<"/proc/net/dev">>,
    case file:open(File, read) of
    	{ok, S} ->
    	    Res = recursive_read(S, Eth, []),
    	    Res;
    	_ -> ["<pre>cannot open:", File, "</pre>"]
    end.

read_playdata(Dev, Match, Num, Res) ->
    case io:get_line(Dev, '') of
    	eof ->
    	    % io:format("To eof, Res:~p~n", [Res]),
    	    Res;
    	Data ->
            % io:format("Data:~p~n", [Data]),
            Start1 = string:chr(Data, $() + 2,
            End1   = string:chr(Data, $,) - 2,
            Find1  = string:sub_string(Data, Start1, End1),
            % io:format("Find1:~p~n", [Find1]),
    	    [Y,M,D] = string:tokens(Find1, "-"),
            % io:format("Y:~p M:~p D:~p~n", [Y,M,D]),
            Date1 = {list_to_integer(Y), list_to_integer(M), list_to_integer(D)},
            % io:format("Date1:~p~n", [Date1]),
            Days1 = calendar:date_to_gregorian_days(Date1),
            Sub = Match - Days1,
            case Sub < Num of
                true ->
                    % io:format("Find1:~p Match:~p Days1:~p Sub:~p~n", [Find1, Match, Days1, Sub]),
                    Start2 = string:chr(Data, ${),
                    End2   = string:chr(Data, $}),
                    Find2  = string:sub_string(Data, Start2, End2),
                    ResPlus = Res ++ "," ++ [list_to_binary(Find2)],
                    % io:format("Find2:~p~n", [Find2]),
                    % io:format("ResPlus:~p~n", [ResPlus]),
                    read_playdata(Dev, Match, Num, ResPlus);
                    
                false -> read_playdata(Dev, Match, Num, Res)
            end
    end. 
    
get_playdata(Num) ->
    File = <<"./json/result.json">>,
    {YMD,_} = calendar:local_time(),
    Match = calendar:date_to_gregorian_days(YMD),
    %%Match = lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Day])),
    % io:format("Match:~p~n", [Match]),
    case file:open(File, read) of
    	{ok, S} ->
    		Res = read_playdata(S, Match, Num, []),
    	    Res;
    	_ -> ["<pre>cannot open:", File, "</pre>"]
    end.


read_file(<<"/monitor">>) ->
    Json = mochijson2:encode([{<<"Tom">>, <<"32">>}, {<<"Lisa">>, <<"30">>}]),
    Json;
read_file(<<"/meminfo">>) ->
    Meminfo = get_meminfo(),
    {_MegaSecs, Secs, MicroSecs} = erlang:now(),
    TimeBin = erlang:integer_to_binary(Secs * 1000000 + MicroSecs),
    Timeinfo = [{<<?TIMENOW>>, TimeBin}],
    Json = mochijson2:encode(Timeinfo ++ Meminfo),
    Json;
read_file(<<"/netinfo0">>) ->
    Meminfo = get_meminfo(),
    Netinfo = get_netinfo("eth0"),
    {_MegaSecs, Secs, MicroSecs} = erlang:now(),
    TimeBin = erlang:integer_to_binary(Secs * 1000000 + MicroSecs),
    Timeinfo = [{<<?TIMENOW>>, TimeBin}],
    Json = mochijson2:encode(Timeinfo ++ Meminfo ++ Netinfo),
    Json;
read_file(<<"/netinfo1">>) ->
    Meminfo = get_meminfo(),
    Netinfo = get_netinfo("eth1"),
    {_MegaSecs, Secs, MicroSecs} = erlang:now(),
    TimeBin = erlang:integer_to_binary(Secs * 1000000 + MicroSecs),
    Timeinfo = [{<<?TIMENOW>>, TimeBin}],
    Json = mochijson2:encode(Timeinfo ++ Meminfo ++ Netinfo),
    Json;
read_file(Path) ->
    %%large:info("Path:~p", [Path]),
    % io:format("Path:~p~n", [Path]),
    File = ["."|binary_to_list(Path)],
    case file:read_file(File) of
    	{ok, Bin} -> Bin;
    	_ -> ["<pre>cannot read:", File, "</pre>"]
    end.