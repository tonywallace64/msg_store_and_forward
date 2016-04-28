%%%-------------------------------------------------------------------
%%% @author tony <tony@faith>
%%% @copyright (C) 2016, tony
%%% @doc
%%%
%%% @end
%%% Created : 26 Apr 2016 by tony <tony@faith>
%%%-------------------------------------------------------------------
-module(mailbox).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([main/1,register/1,send/2,get_mail/1]).
-export([test/0]).

-define(SERVER, ?MODULE).
-define(MAILDIR, <<".mailbox">>).
-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
main(_) ->
    start_link().

register(Name) ->
    gen_server:call(?SERVER,{register,Name}).

send(Recipient_List,Msg) ->
    gen_server:call(?SERVER,{send,Msg,Recipient_List}).
  
get_mail(Name) ->  
    gen_server:call(?SERVER,{get_mail,Name}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    ensure_dir(?MAILDIR),
    {ok, #state{}}.

ensure_dir(Dir) ->
    ensure_dir(filelib:is_dir(Dir),Dir).

ensure_dir(true,_) ->
    ok;
ensure_dir(false,Dir) ->
    ensure_dir(filename:dirname(Dir)),
    file:make_dir(filename:basename(Dir)).

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({register,Name}, _From, State) ->
    Reply = svr_register(Name),
    {reply, Reply, State};
handle_call({send,Msg,Recipient_List}, _From, State) ->
    Reply = svr_send(Msg,Recipient_List,[]),
    {reply, Reply, State};
handle_call({get_mail,Name}, _From, State) ->
    Reply = svr_getmail(Name),
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

svr_register(Name) ->
    %% Make mailbox Name
    Mailbox_Path = [?MAILDIR,Name],
    maybe_mkfile(filelib:is_regular(Mailbox_Path),Mailbox_Path).

maybe_mkfile(true,_) ->
    ok;
maybe_mkfile(false,Mailbox_Path) ->
    file:write_file(filename:join(Mailbox_Path),<<>>).


%% ===========
svr_send(Msg,[Name|Rest],Errors) ->
    Mailbox_Path = [?MAILDIR,Name],
    NewErrors = check_valid_mbox(Mailbox_Path,Errors),
    maybe_append_msg(Mailbox_Path,Msg),
    svr_send(Msg,Rest,NewErrors);
svr_send(_,[],[]) ->
    ok;
svr_send(_,[],Errors) ->
    {error,Errors}.

check_valid_mbox(MP,E) ->
    check_valid_mbox(filelib:is_regular(filename:join(MP)),MP,E).

check_valid_mbox(true,_,E) ->
    E;
check_valid_mbox(false,[?MAILDIR,Name],E) ->
    [{unknown_recipient,Name}|E].

maybe_append_msg(MB,Msg) ->
    maybe_append_msg(filelib:is_regular(filename:join(MB)),MB,Msg).

maybe_append_msg(true,MB,Msg) ->
    {ok,Hdl} = file:open(filename:join(MB),[append]),
    file:close(Hdl);
maybe_append_msg(false,_MB,_Msg) ->
    error.
    
%% ==========
svr_getmail(Name) ->
    Mailbox_Path = filename:join([?MAILDIR,Name]),
    maybe_getmail(file:consult(Mailbox_Path),Mailbox_Path).

maybe_getmail({ok,Mail},Mailbox_Path) ->
    file:write_file(Mailbox_Path, <<>>),
    Mail;
maybe_getmail({error,_},_) ->
    [].

%% Test
test() ->
    test1().

test1() ->
    {ok,_Pid} = start_link(),
    register('john_doe'),
    send(['john_doe'],"Hello"),
    ["Hello"]=get_mail('john_doe'),
    passed.
