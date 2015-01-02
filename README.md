[![Build Status](https://travis-ci.org/tokuhirom/Daiku.svg?branch=master)](https://travis-ci.org/tokuhirom/Daiku) [![Coverage Status](https://img.shields.io/coveralls/tokuhirom/Daiku/master.svg)](https://coveralls.io/r/tokuhirom/Daiku?branch=master)
# NAME

Daiku - Make for Perl

# SYNOPSIS

    #! perl
    use Daiku;
    use autodie ':all';

    desc 'do all tasks';
    task 'all' => 'foo';
    file 'foo' => 'foo.o' => sub {
        system "gcc -c foo foo.o";
    };
    rule '.o' => '.c' => sub {
        system "gcc -c foo.o foo.c";
    };

    build shift @ARGV || 'all';

# DESCRIPTION

Daiku is yet another build system for Perl5.

# USAGE GUIDE

## use Daiku

By declaring `use Daiku` in your own Perl script,
you can use [Daiku](https://metacpan.org/pod/Daiku) DSL to write your build procedure.

See ["SYNOPSIS"](#synopsis) for example of this usage.

## [daiku](https://metacpan.org/pod/daiku) command and Daikufile

[Daiku](https://metacpan.org/pod/Daiku) comes with [daiku](https://metacpan.org/pod/daiku) command-line tool.
Just like `make` reads `Makefile`, [daiku](https://metacpan.org/pod/daiku) reads `Daikufile` and runs the build procedure.

See [daiku](https://metacpan.org/pod/daiku) for detail.

# FUNCTIONS

The following functions are exported by default.

## `desc`

- `desc $desc:Str`

Description of the following task.

## `task`

- `task $dst:Str, \@deps:ArrayRef[Str]`
- `task $dst:Str, \@deps:ArrayRef[Str], \&code:CodeRef`
- `task $dst:Str, $deps:Str`
- `task $dst:Str, $deps:Str, \&code:CodeRef`
- `task $dst:Str, \&code:CodeRef`

Register a .PHONY task.

If `\&code` is passed, it is executed when [Daiku](https://metacpan.org/pod/Daiku) builds this task.

    $code->($task, @args)

where `$task` is a [Daiku::Task](https://metacpan.org/pod/Daiku::Task) object, and `@args` is the arguments for the task.

You can access attributes of the task via `$task` object.

    $dst = $task->dst;
    $array_ref_of_deps = $task->deps;

You can pass arguments to a task via `build()` function. For example,

    task "all", sub { my ($task, @args) = @_; ... };
    build("all[xxx yyy]");

then, `@args` is `("xxx", "yyy")`.

As you see in the above example, arguments are specified inside brackets,
and they are parsed as if they were command-line arguments (i.e., arguments are separated by spaces).

You can also specify task arguments via [daiku](https://metacpan.org/pod/daiku) command.

## file

- `file $dst, $deps:Str, \&code:CodeRef`
- `file $dst, \@deps:ArrayRef[Str], \&code:CodeRef`

Register a file creation rule.

The `\&code` is executed when [Daiku](https://metacpan.org/pod/Daiku) builds the file. It is supposed to create the file named `$dst`.

    $code->($file)

where `$file` is a [Daiku::File](https://metacpan.org/pod/Daiku::File) object.

You can access attributes of the file task via `$file` object.

    $dst = $file->dst;
    $array_ref_of_deps = $file->deps;

## rule

- `rule $dst:Str, $src:Str, \&code:CodeRef`
- `rule $dst:Str, \@srcs:ArrayRef[Str], \&code:CodeRef`
- `rule $dst:Str, \&srcs:CodeRef, \&code:CodeRef`

Register a suffix rule. It's the same as following code in Make.

    .c.o:
        cc -c $<

The `\&code` is executed when [Daiku](https://metacpan.org/pod/Daiku) builds this task.

    $code->($rule, $dst_filename, @src_filenames)

where `$rule` is a Daiku::SuffixRule object, `$dst_filename` is the destination filename
and `@src_filenames` are the source filenames.
The `$code` is supposed to create the file named `$dst_filename`.

If you pass a CodeRef as `\&srcs`, it is executed to derive source filenames.

    @src_filenames = $srcs->($dst_filename)

For example,

    rule '.o' => sub {
        my ($file) = @_;
        $file =~ s/\.o$//;
        ("$file.h", "$file.c");
    } => sub {
        my ($task, $dst, $src_h, $src_c) = @_;
        compile($src_c, $dst);
    };

You can also return an ArrayRef from `\&srcs` instead of a list.
In that case, the ArrayRef is just flattened.

## build

- `build $task : Str`

Build one object named `$task`.

_Return Value_: The number of built jobs.

## namespace

- `namespace $namespace:Str, \&codeblock:CodeRef`

Declare a namespace of tasks. Namespaces can be nested.

With namespaces, you can organize your tasks in a hierarchical way.
For example,

    namespace n1 => sub {
        desc 't1';
        task task1 => sub { };
    
        namespace n2 => sub {
            desc 't2';
            task task2 => sub { };
        };
    };

The full task name includes all containing namespaces joined with colons (`:`).

    $ daiku n1:task1
    $ daiku n1:n2:task2

## sh

- `sh @command:List[Str]`

Executes the `@command`.

This is similar to `system()` built-in function, but it throws an exception when the command returns a non-zero exit value.

# NOTE

This module doesn't detect recursion, but Perl5 can detect it.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF GMAIL COM>

# SEE ALSO

[Rake](http://rake.rubyforge.org/), [make(1)](http://man.he.net/man1/make)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
