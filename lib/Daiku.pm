use strict;
use warnings FATAL => 'recursion';

package Daiku;
use 5.008001;
our $VERSION = '1.00';
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

=head1 FUNCTIONS

=over 4

=item C<< desc $desc:Str >>

Description of following task.

=item C<< task $name:Str, \@deps:ArrayRef[Str] >>

=item C<< task $name:Str, \@deps:ArrayRef[Str], \&callback >>

=item C<< task $name:Str, $deps:Str >>

=item C<< task $name:Str, $deps:Str, \&callback >>

Register .PHONY task to registrar.

=item C<< file $name, $deps:Str, \&code >>

=item C<< file $name, \@deps:ArrayRef[Str], \&code >>

Register a file creation rule.

=item C<< rule $dst:Str, $src:Str, \&callback:CodeRef >>

Register a suffix rule. It's same as following code on Make.

    .c.o:
        cc -c $<

=item C<< build $task : Str >>

Build one object named $task.

=item C<< namesace $namespace:Str, \&codeblock >>

Declare namespace of tasks. Namespaces are separated by colon.

=back

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
