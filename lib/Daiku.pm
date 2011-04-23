use strict;
use warnings FATAL => 'recursion';

package Daiku;
use 5.008001;
our $VERSION = '0.01';
use Daiku::Engine;

sub import {
    my ($class) = @_;
    my $pkg = caller(0);
    no strict 'refs';
    *{"${pkg}::task"} = \&_task;
    *{"${pkg}::file"} = \&_file;
    *{"${pkg}::suffix_rule"} = \&_suffix_rule;
    my $engine = Daiku::Engine->new();
    *{"${pkg}::engine"} = sub { $engine };
    *{"${pkg}::build"} = sub { $engine->build(@_) };
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
    my $task = Daiku::Task->new( %args );
    caller(0)->engine->register($task);
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

# suffix_rule '.c' => '.o' => sub { ... };
sub _suffix_rule($$&) {
    my %args;
    @args{qw/dst src code/} = @_;
    my $suffix_rule = Daiku::SuffixRule->new( %args );
    caller(0)->engine->register($suffix_rule);
}



1;
__END__

=encoding utf8

=head1 NAME

Daiku - Build system

=head1 SYNOPSIS

    use Daiku;

    my $daiku = Daiku->new();
    $daiku->register('foo' => [qw/foo.o/] => sub {
        system "gcc -c foo foo.o";
    });
    $daiku->register('foo.o' => [qw/foo.c/] => sub {
        system "gcc -c foo.o foo.c";
    });
    $daiku->build("foo");

=head1 DESCRIPTION

Daiku is

=head1 NOTE

This module is a software build system like Rake.

This module doesn't detect recursion, but Perl5 can detect it.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
