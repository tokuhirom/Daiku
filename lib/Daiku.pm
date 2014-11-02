use strict;
use warnings FATAL => 'recursion';

package Daiku;
use 5.008001;
our $VERSION = '1.001';
use Daiku::Registry;
use IPC::System::Simple ();

sub import {
    my ($class) = @_;
    my $pkg = caller(0);
    no strict 'refs';
    *{"${pkg}::desc"} = \&_desc;
    *{"${pkg}::task"} = \&_task;
    *{"${pkg}::file"} = \&_file;
    *{"${pkg}::rule"} = \&_rule;
    *{"${pkg}::sh"}   = \&IPC::System::Simple::run;
    *{"${pkg}::namespace"} = \&_namespace;
    my $engine = Daiku::Registry->new();
    *{"${pkg}::engine"} = sub { $engine };
    *{"${pkg}::build"} = sub { $engine->build(@_) };
}

sub _desc($) {
    my $desc = shift;

    caller(0)->engine->temporary_desc($desc);
}

# task 'all' => ['a', 'b'];
# task 'all' => ['a', 'b'] => sub { ... };
sub _task($$;&) {
    my %args;
    $args{dst} = shift @_;
    if (ref($_[-1]) eq 'CODE') {
        $args{code} = pop @_;
    }
    if (@_) {
        $args{deps} = shift @_;
        $args{deps} = [$args{deps}] if !ref $args{deps};
    }
    my $engine = caller(0)->engine;
    my $desc = $engine->clear_temporary_desc;
    if (defined $desc) {
        $args{desc} = $desc;
    }
    $args{dst} = join ':', @{ $engine->namespaces }, $args{dst};

    my $task = Daiku::Task->new( %args );
    $engine->register($task);
}

# file 'all' => ['a', 'b'];
# file 'all' => 'a';
# file 'all' => ['a', 'b'] => sub { ... };
sub _file($$;&) {
    my %args;
    $args{dst} = shift @_;
    if (ref($_[-1]) eq 'CODE') {
        $args{code} = pop @_;
    }
    if (@_) {
        $args{deps} = shift @_;
        $args{deps} = [$args{deps}] if !ref $args{deps};
    }
    my $file = Daiku::File->new( %args );
    caller(0)->engine->register($file);
}

# rule '.c' => '.o' => sub { ... };
sub _rule($$;&) {
    my %args;
    @args{qw/dst src code/} = @_;
    delete $args{code} unless defined $args{code};
    my $rule = Daiku::SuffixRule->new( %args );
    caller(0)->engine->register($rule);
}

sub _namespace($$) {
    my ($namespace, $code) = @_;

    my $engine = caller(0)->engine;
    push @{ $engine->namespaces }, $namespace;
    $code->();
    pop @{ $engine->namespaces };
}

1;
__END__

=encoding utf8

=head1 NAME

Daiku - Make for Perl

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Daiku is yet another build system for Perl5.

=head1 USAGE GUIDE

=head2 use Daiku

By declaring C<< use Daiku >> in your own Perl script,
you can use L<Daiku> DSL to write your build procedure.

See L</SYNOPSIS> for example of this usage.

=head2 daiku command and Daikufile

L<Daiku> comes with L<daiku> command-line tool.
Just like C<make> reads C<Makefile>, L<daiku> reads C<Daikufile> and runs the build procedure.

See L<daiku> for detail.

=head1 FUNCTIONS

=head2 desc

=over 4

=item C<< desc $desc:Str >>

=back

Description of the following task.


=head2 task

=over 4

=item C<< task $dst:Str, \@deps:ArrayRef[Str] >>

=item C<< task $dst:Str, \@deps:ArrayRef[Str], \&code:CodeRef >>

=item C<< task $dst:Str, $deps:Str >>

=item C<< task $dst:Str, $deps:Str, \&code:CodeRef >>

=item C<< task $dst:Str, \&code:CodeRef >>

=back

Register a .PHONY task.

If C<\&code> is passed, it is executed when L<Daiku> builds this task.

    $code->($task, @args)

where C<$task> is a L<Daiku::Task> object, and C<@args> is the arguments for the task.

You can access attributes of the task via C<$task> object.

    $dst = $task->dst;
    $array_ref_of_deps = $task->deps;

You can pass arguments to a task via C<build()> function. For example,

    task "all", sub { my ($task, @args) = @_; ... };
    build("all[xxx yyy]");

then, C<@args> is C<< ("xxx", "yyy") >>.

As you see in the above example, arguments are specified inside brackets,
and they are parsed as if they were command-line arguments (i.e., arguments are separated by spaces).

You can also specify task arguments via L<daiku> command.

=head2 file

=over 4

=item C<< file $dst, $deps:Str, \&code:CodeRef >>

=item C<< file $dst, \@deps:ArrayRef[Str], \&code:CodeRef >>

=back

Register a file creation rule.

The C<\&code> is executed when L<Daiku> builds the file. It is supposed to create the file named C<$dst>.

    $code->($file)

where C<$file> is a L<Daiku::File> object.

You can access attributes of the file task via C<$file> object.

    $dst = $file->dst;
    $array_ref_of_deps = $file->deps;

=head2 rule

=over 4

=item C<< rule $dst:Str, $src:Str, \&code:CodeRef >>

=item C<< rule $dst:Str, \@srcs:ArrayRef[Str], \&code:CodeRef >>

=item C<< rule $dst:Str, \&srcs:CodeRef, \&code:CodeRef >>

=back

Register a suffix rule. It's the same as following code in Make.

    .c.o:
        cc -c $<

The C<\&code> is executed when L<Daiku> builds this task.

    $code->($rule, $dst_filename, @src_filenames)

where C<$rule> is a L<Daiku::SuffixRule> object, C<$dst_filename> is the destination filename
and C<@src_filenames> are the source filenames.
The C<$code> is supposed to create the file named C<$dst_filename>.

If you pass a CodeRef as C<\&srcs>, it is executed to derive source filenames.

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

You can also return an ArrayRef from C<\&srcs> instead of a list.
In that case, the ArrayRef is just flattened.

=head2 build

=over 4

=item C<< build $task : Str >>

=back

Build one object named C<$task>.

I<Return Value>: The number of built jobs.

=head2 namespace

=over 4

=item C<< namespace $namespace:Str, \&codeblock:CodeRef >>

=back

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

The full task name includes all containing namespaces joined with colons (C<:>).

    $ daiku n1:task1
    $ daiku n1:n2:task2

=head2 sh

=over 4

=item C<< sh @command:List[Str] >>

=back

Executes the C<@command>.

This is similar to C<system()> built-in function, but it throws an exception when the command returns a non-zero exit value.


=head1 NOTE

This module doesn't detect recursion, but Perl5 can detect it.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Rake|http://rake.rubyforge.org/>, L<make(1)>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
