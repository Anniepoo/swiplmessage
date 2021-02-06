NOte to self - also include using library(error)
============

Note - should I include library debug?

> I'm wondering if I should also discuss the debug library in this
> tutorial.


I think that makes sense.  They are quite closely related. (Jan)

===============


>Quintus invented that.  Please mention that.

===============

90 ?- print_message(error, hello).
ERROR: Unknown message: hello
true.

This confuses me about why it would say "Unknown message".  How do I get anything else?

===============

By defining rules for prolog:message//1.  That is the elegant way.  There
is also a dirty way: using the term `format(Format, Args)`.  The idea is
that messages are specified by well defined terms that may be used by
hooks to act upon and that may be mapped to different natural language
representations.  The message system is copied modelled after Quintus,
although the different language translations never materialized and the
system is extended a little.

    Cheers --- Jan

===============
Annnie -
it would be helpful if the format(Format, Args) was documented b etter.

===================
The message terms are not documented anyway. The `format` term is a
dirty hack that might better be left undocumented before everyone starts
using the wrong thing. More needed is a good tutorial that explains how
to deal with the message infrastructure:

    - How to define new messages for your own libraries
    - How to act on messages (hooking, sending them elsewhere, ignoring,
      collecting, etc.)
    - How to combine the message system with exceptions.

Lacking that, search the system libraries :-(

    Cheers --- Jan

===================

Alan Baljeu -

Until this series of emails, I didn't even know there was a message system worth searching for in libraries.  All I wanted was bold red text for outputing an error message.

===================

Douglas -

By defining rules for prolog:message//1.  That is the elegant way.


I love the message//1 system 

Its great that it is
:- multifile message//1.

But could it also be dynamic ?

In the past it has been troublesome I cant get my translators in first or last (whichever I want) 
(We cant predict reliably in which order they will be loaded)

But at least we can assert(a/z) or re-arrange or redefine to suite the needs of the day.

===================


I don't really like the idea of dynamic message translation.  Smells
messy.  Can you describe what you are trying to achieve, so maybe we
can think of something cleaner?

    Cheers --- Jan

==================
Douglas

I totally like it when it's used for inter-process event hooks such as knowing a file just got reloaded.

But there was a couple times I wanted  to intercept and ignore cliopatria's "updating from GIT"  every 2 seconds :)

Some message handlers when they get the message don't process and call fail (instead they stop the message for being received by later listeners)  (maybe this isnt always the case)  

Sometimes I've fantasized how nice if i can asserta/1 the hook .. I would promise to always fail.. but I'd have a better idea of the events available/happening and not be forced to miss them.

===================


??? message_hook/3 _is_ dynamic. It is completely ok to asserta this, do
something and remove it again. You can use that to temporary ignore
messages, collect them, send them elsewhere, print a different text from
the default one, etc. Typically you use thread_message_hook/1, which is
a thread-local version that is called first. This ensures you only
capture messages from the current thread.  E.g.

silent(Goal) :-
    setup_call_cleanup(
        asserta((user:thread_message_hook(_,informational,_)), Ref),
        Goal,
        erase(Ref)).

    Cheers --- Jan

===================
Douglas

Maybe the only issue is it is handling the job of two separate systems

   - Translating exception and information into readable forms

   - using them for knowing when to update UI (non vital to program control let say)
      of more vitally act on messages (hooking, sending them elsewhere, ignoring,  collecting, etc.)

===================
Douglas
Aha .. you are correct.. I had confused the two systems:   message/3 and message_hook/3  

==================

Jan

> ignoring,  collecting, etc.)

Most of this seems to be dealt with fairly well by the original Quintus
design. The only exception I see is that you may want to use messages
for triggering some action in the program. You typically do this by
adding a message hook that initiates the side effect and fails, so other
handlers are not harmed. At the same time you may want to prevent the
message from being printed in the normal way, in which case you want to
succeed, stopping handlers of the first type :-(

Note that if the original idea is to create a silent message for other
parts of the program to act on, it might be wiser to use
library(broadcast).

Otherwise, I guess it should work fine if hooks with side effects are
added using asserta and hooks that prevent printing with assertz. And
yes, if you also load message_hook/3 clauses from files it easily gets
messy :(  That is not very different from adding event listeners in a
browser :(

So far, the main issue seems lack of documentation that explains the
overall story and gives tutorial examples.

============
douglas

It is still easy maintainable even if it gets messy I can always predict even if some file was loaded first or loaded last.. If it
 asserta'd.. I will be first (And if it fail, It'll do no harm)     (assertz not so sure)
    
% show the warnings origins
:- multifile(user:message_hook/3). 
:- dynamic(user:message_hook/3).
:- asserta((user:message_hook(Term, Kind, Lines):-  buggery_ok, (Kind= warning;Kind= error),Term\=syntax_error(_), 
     dmsg(user:message_hook(Term, Kind, Lines)),
     fail)).  

=============

Jan 

>More needed is a good tutorial that explains how

to deal with the message infrastructure:

- How to define new messages for your own libraries
- How to act on messages (hooking, sending them elsewhere, ignoring,
collecting, etc.)
- How to combine the message system with exceptions.




OK, OK, I know when I've been recruited....

Jan, if you'll a) tolerate some queries from me, and b) expand on the above outline a bit, so I at least know what areas to read in docs and sources, then
I'll write a tutorial.

===============

On 08/21/2015 03:55 PM, Anne Ogborn wrote:
>> More needed is a good tutorial that explains how
>
> to deal with the message infrastructure:
>
> - How to define new messages for your own libraries - How to act on
> messages (hooking, sending them elsewhere, ignoring, collecting,
> etc.) - How to combine the message system with exceptions.
>
>
>
> OK, OK, I know when I've been recruited....
>
> Jan, if you'll a) tolerate some queries from me, and b) expand on the
> above outline a bit, so I at least know what areas to read in docs
> and sources, then I'll write a tutorial.

Great!  I put an initial outline below, so people have at least a clue.

    Cheers --- Jan

================================================================
The predicates are all described here:

  http://www.swi-prolog.org/pldoc/man?section=printmsg

What is lacking is notably a story how it all fits together.  I'll
try to give that here.

# Aims

  - Allow the system to act on them as `events'.
  - Provide multi-lingual support (never realised).
  - Allow redirecting (file, a window, etc.) and suppressing

    messages.

  - Allow collection messages.

# Basic processing

  - If a message needs to be printed, the code calls print_message/2
    as show below, where Kind indicates the role of the message and
    Term is an arbitrary Prolog term that carries the content
    (meaning?) of the message, but is explicitly not the textual
    message itself.

    print_message(Kind, Term)

    For example, all system exceptions are valid values for Term and
    thus we can do this:

        ?- catch(A is 1/0, E, print_message(error, E)).
    ERROR: //2: Arithmetic: evaluation error: `zero_divisor'
    E = error(evaluation_error(zero_divisor), context((/)/2, _G677)).

  - print_message/2 takes the following steps:

    - Call prolog:message//1 to translate the message into a sequence
      of tokens.  The tokens represent the human readable message, but
      not yet as text.  The known tokens are described with
      print_message_lines/3.

    - Call the hook below using the initial Term, Kind and computed
      Tokens.  This is a thread_local predicate and thus only hooks
      messages generated in a particular thread.

    thread_message_hook(Term, Kind, Tokens)

      On success, further processing stops.

    - Call the global hook below. Again, on success further processing
stops.

    message_hook(Term, Kind, Tokens)

    - If the hooks fail, print_message/2 continues by respecting the
      defaults defined by the hook message_property/2 and calling
      print_message_lines/3.

  - print_message_lines/3 has the task of emitting the message to a stream.
    If you want it elsewhere, use with_output_to/2 or interpret the tokens
    yourself.  It is again hookable using prolog:message_line_element/2,
    which is used by library(ansi_term) to give some color to message
    elements.

# Defining new messages

If you want to add a message for your library, choose a term for it.
Note that the term-space is shared by the entire process, so choose
something based on the library name to make it clear where the message
comes from.  Next, define a rule for prolog:message//1.  For example:

:- multifile prolog:message//1.

prolog:message(hello(To)) -->
    [ 'Hello ~p!'-[To] ].

Now you can do

    ?- print_message(informational, hello(world)).
    % hello world!

# Hooking messages

There are two types of hooks: hooks that trigger side effects and hooks
that modify the output of the message or send it elsewhere. For example,
make/0 emits `make(done(Reload))`, where Reload is a set of files being
reloaded. You can use that to take additional actions as below. Note
that we `fail` to keep processing the message.

user:message_hook(make(done(Reload)), _Kine, _Lines) :-
    restart_services(Reload),
    fail.

Alternatively, we may want to run some code without messages.  We
then use

silent(Goal) :-
    setup_call_cleanup(
        asserta(user:thread_message_hook(_,_,_), Ref),
        Goal,
        erase(Ref)).

Here, we succeed and try to get before all other hooks.

# Future work

The original system by Quintus could load different sets of message//1
rules depending on the desired (human) language.  We might want to get
that back at some point.  Considering (web) server applications however,
different languages should co-exist, so we can print the same term in
different languages depending on the user.

SWISH would profit from a more HTML oriented token set, so it can render
messages with embedded links (documentation, errors, home pages, etc),
render tables, etc.

==============

> I'm not sure what 'Allow collection messages' is?


Well, more or less what the redirection does.  At some places I have
call_collect_messages(Goal, Messages).  That is useful for testing
code that may generate messages or reason about the result of goals
that may have produced messages.

    Cheers --- Jan

