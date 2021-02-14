# NAME

Command::Template - A template to build command line arrays, and run them

# VERSION

This document describes Command::Template version {{\[ version \]}}.

<div>
    <a href="https://travis-ci.org/polettix/Command-Template">
    <img alt="Build Status" src="https://travis-ci.org/polettix/Command-Template.svg?branch=master">
    </a>
    <a href="https://www.perl.org/">
    <img alt="Perl Version" src="https://img.shields.io/badge/perl-5.24+-brightgreen.svg">
    </a>
    <a href="https://badge.fury.io/pl/Command-Template">
    <img alt="Current CPAN version" src="https://badge.fury.io/pl/Command-Template.svg">
    </a>
    <a href="http://cpants.cpanauthors.org/dist/Command-Template">
    <img alt="Kwalitee" src="http://cpants.cpanauthors.org/dist/Command-Template.png">
    </a>
    <a href="http://www.cpantesters.org/distro/O/Command-Template.html?distmat=1">
    <img alt="CPAN Testers" src="https://img.shields.io/badge/cpan-testers-blue.svg">
    </a>
    <a href="http://matrix.cpantesters.org/?dist=Command-Template">
    <img alt="CPAN Testers Matrix" src="https://img.shields.io/badge/matrix-@testers-blue.svg">
    </a>
</div>

# SYNOPSIS

    use Command::Template qw< command_runner command_template cr ct >;

    #### COMMAND EXPANSION GENERATION (NO EXECUTION) ####
    # command_template is aliased to ct
    my $ct = command_template(qw{ ls [options=-l] <dir> });

    # @c1 = qw< ls -l / >
    my @c1 = $ct->generate(dir => '/');

    # @c2 = qw< ls -la / >
    my @c2 = $ct->generate(dir => '/etc', options => '-la');

    # @c3 = @c4 = qw< ls /usr/bin >
    my @c3 = $ct->generate(dir => '/usr/bin', options => undef);
    my @c4 = $ct->generate(dir => '/usr/bin', options => []);

    # @c5 = qw< ls -l -a /usr/bin >
    my @c5 = $ct->generate(dir => '/usr/bin', options => [qw< -l -a >]);


    #### COMMAND RUNNING (VIA IPC::Run) ####
    # command_runner is aliased to cr
    my $runner = command_runner(qw{ ls [options=-l] <dir> });

    # run command qw< ls -l / >, returns a Command::Template::RunRecord
    my $r = $runner->run(dir => '/');
    my $run_successful  = $r->success;
    my $exit_code       = $r->exit_code; # 0 is OK as usual in UNIX
    my $received_signal = $r->signal;    # e.g. if killed, ...
    my $stdout          = $r->stdout;
    my $stderr          = $r->stderr;
    my $merged          = $r->merged; # stderr then stdout, no newlines
                                      # added

    # command_runner is aliased to cr
    my $other_runner = cr(qw< cat >); # gives stdin as stdout
    my $message = "blah\nblah";
    $r = $other_runner->run(-stdin => $message);
    my $equal = $r->stdout eq $message; # true

# DESCRIPTION

`Command::Template` eases the creation of objects that help building up
command-lines and/or to run them.

As an example, it might be needed to generate multiple commands
according to the following template:

    ls [options=-l] <dir>

i.e. the `ls` command, where there might be some `options` (defaulting
to option `-l`) and there MUST be a directory `dir` (which in this
case has no default).

The following possible expansions adhere to the template above:

    ls -l /
    ls -la /usr
    ls -l -a /etc
    ls /run

while the following does not (because there is no directory, which we
want because we used the `<...>` form):

    ls -l

The module provides two different interfaces:

- ["command\_template"](#command_template) allows generating the commands as lists, which are
then supposed to be used somehow (e.g. provided to `system`);
- ["command\_runner"](#command_runner) allows running the commands via [IPC::Run](https://metacpan.org/pod/IPC::Run).

Both adhere to the same ["Expansion Rules"](#expansion-rules) explained below and
implemented in [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance).

## Expansion Rules

A template in `Command::Template` resembles the way commands are
explained in documentation:

- required parameters are enclosed by `<...>` delimiters;
- optional parameters are enclosed by `[...]` delimiters.

Parameters name can only start with a letter or an underscore, then can
be followed by any sequence of underscores, letters, and digits. The
following names are valid:

    foo
    bar
    dir
    baz1
    baz_2
    name_or_surname

Any parameter can be optionally set with a default value, which can be
set with the `=` sign, like in the following examples:

    <foo=this is FOO>
    <bar=  BAR  >

Spaces are preserved starting immediately after the `=` sign.

When [Template::Command::Instance](https://metacpan.org/pod/Template::Command::Instance) expands a template, it uses a hash
that maps each name to the value it should take:

- if `undef`, then the corresponding item is _removed_ from the command.
This allows getting rid of a default value set for an optional
parameter; it is an error (leading to an exception) if the parameter is
required;
- if any other plain scalar, it is set as the value in the specific
command line parameter location;
- if an array reference, all items inside are put in the specific command
line parameter location.

The last possibility provides the flexibility to e.g. set options that
require a parameter (e.g. it would be the case of option `-name` for
command `find`).

## Running Commands

While [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance) only allows generating command
lines as lists of strings, [Command::Template::Runner](https://metacpan.org/pod/Command::Template::Runner) allows running
them by means of [IPC::Run](https://metacpan.org/pod/IPC::Run).

All the heavy work for expanding is provided by
[Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance) behind the scenes; the ["SYNOPSIS"](#synopsis)
contains examples of actual running of commands.

# INTERFACE

## **command\_runner**

    # parse a command line template and use it for running commands
    my $cr = command_runner(qw{ ls [options=-l] <dir> });

Returns a [Command::Template::Runner](https://metacpan.org/pod/Command::Template::Runner) object with a `run` method that
allows actually running generated commands via [IPC::Run](https://metacpan.org/pod/IPC::Run).

Each run returns a [Command::Template::Runner::Record](https://metacpan.org/pod/Command::Template::Runner::Record) object that allows
peeking into the actual result of the run.

    my $r = $cr->run(options => '-la', '/etc');
    say $r->stdout if $r->success;

## **cr**

Alias for ["command\_runner"](#command_runner).

## **command\_template**

    my $ct = command_template(qw{ galook <foo> <bar=N> [baz] [sil=Y] })

Returns a [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance) object with a `generate`
method that performs the actual expansion, returning a list of strings
representing the command line.

## **ct**

Alias for ["command\_template"](#command_template).

# EXTENDING

If extending `Command::Template` is of interest, here are a few hints:

- class [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance) encapsulates parsing a command
template and expanding it for generating command lists, based on a hash
with values binding;
- class [Command::Template::Runner](https://metacpan.org/pod/Command::Template::Runner) provides a simple running facility
around [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance) that uses [IPC::Run](https://metacpan.org/pod/IPC::Run) to run
expanded commands, returning the result as a
[Command::Template::Runner::Record](https://metacpan.org/pod/Command::Template::Runner::Record) object.
- class [Command::Template::Runner::Record](https://metacpan.org/pod/Command::Template::Runner::Record) provides accessors into the
outcome of a single run from [Command::Template::Runner](https://metacpan.org/pod/Command::Template::Runner).

Possible reasons for expanding might be:

- different or additional rules for expansions are needed. If this is the
case, the alternative to [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance) must provide a
`generate` method; [Comman::Template::Runner](https://metacpan.org/pod/Comman::Template::Runner) can still be used, as
long as a reference to the alternative object for the instance is passed
to the constructor.
- a different running facility is needed. In this case, it suffices to
impelement a new runner class, leveraging [Command::Template::Instance](https://metacpan.org/pod/Command::Template::Instance)
for the command expansion.

# BUGS AND LIMITATIONS

Minimum perl version 5.24.

Report bugs through GitHub (patches welcome) at
[https://github.com/polettix/Command-Template](https://github.com/polettix/Command-Template).

# AUTHOR

Flavio Poletti <flavio@polettix.it>

# COPYRIGHT AND LICENSE

Copyright 2021 by Flavio Poletti <flavio@polettix.it>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
