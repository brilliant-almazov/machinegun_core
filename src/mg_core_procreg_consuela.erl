%%%
%%% Copyright 2019 RBKmoney
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%

-module(mg_core_procreg_consuela).

%%

-behaviour(mg_core_procreg).

-export([ref/2]).
-export([reg_name/2]).
-export([select/2]).

-export([start_link/5]).
-export([call/4]).

-type options() :: #{
    pulse => mg_core_pulse:handler()
}.

%%

-spec ref(options(), mg_core_procreg:name()) ->
    mg_core_procreg:ref().
ref(_Options, Name) ->
    {via, consuela, Name}.

-spec reg_name(options(), mg_core_procreg:name()) ->
    mg_core_procreg:reg_name().
reg_name(Options, Name) ->
    ref(Options, Name).

-spec select(options(), mg_core_procreg:name_pattern()) ->
    [{mg_core_procreg:name(), pid()}].
select(_Options, NamePattern) ->
    consuela:select(NamePattern).

-spec start_link(options(), mg_core_procreg:reg_name(), module(), _Args, list()) ->
    mg_core_procreg:start_link_ret().
start_link(_Options, RegName, Module, Args, Opts) ->
    try gen_server:start_link(RegName, Module, Args, Opts) of
        {ok, Pid} ->
            {ok, Pid};
        {error, {consuela, Details}} ->
            {error, map_error(Details)};
        {error, Reason} ->
            {error, Reason}
    catch
        exit:{consuela, Details} ->
            {error, map_error(Details)}
    end.

-spec call(options(), mg_core_procreg:ref(), _Call, timeout()) ->
    _Reply.
call(_Options, Ref, Call, Timeout) ->
    try gen_server:call(Ref, Call, Timeout) catch
        exit:{{consuela, Details}, _MFA}:Stacktrace ->
            erlang:raise(exit, map_error(Details), Stacktrace)
    end.

-spec map_error(_Details) ->
    tuple().
map_error(Details) ->
    {transient, {registry_unavailable, Details}}.
