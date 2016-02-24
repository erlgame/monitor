# monitor
server monitor

use rebar:
> git init
> touch README.md
> git add README.md
> git commit -m "add README.md"
> rebar create-app appid=monitor
> mkdir apps && mv src apps/
%% modify rebar.config
%% modify monitor.app.src
%% modify apps/rebar.config
> mkdir rel && cd rel
> rebar create-node nodeid=monitor
%% modify reltool.config
> cd ..
> rebar get-deps
> rebar clean
> rebar compile
> ps aux | grep monitor | grep -v 'grep' | awk '{print $2}' | xargs kill
> cd rel && rebar generate && cd ..

get help:
http://blog.chinaunix.net/xmlrpc.php?r=blog/article&uid=429659&id=4752895