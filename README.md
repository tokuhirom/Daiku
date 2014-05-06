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

# FUNCTIONS

- `desc $desc:Str`

    Description of following task.

- `task $name:Str, \@deps:ArrayRef[Str]`
- `task $name:Str, \@deps:ArrayRef[Str], \&callback`
- `task $name:Str, $deps:Str`
- `task $name:Str, $deps:Str, \&callback`

    Register .PHONY task to registrar.

- `file $name, $deps:Str, \&code`
- `file $name, \@deps:ArrayRef[Str], \&code`

    Register a file creation rule.

- `rule $dst:Str, $src:Str, \&callback:CodeRef`

    Register a suffix rule. It's same as following code on Make.

        .c.o:
            cc -c $<

- `build $task : Str`

    Build one object named $task.

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
