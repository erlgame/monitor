-module(config).

-export([get/1, get/2]).

-define(APPLICATION, monitor).

get(Key) -> get(Key, undefined).

-spec get(Key :: atom(), Default :: term()) -> {ok, Value :: term()}.
get(Key, Default) ->
    case application:get_env(?APPLICATION, Key) of
    	undefined -> {ok, Default};
    	Other -> Other
    end.
