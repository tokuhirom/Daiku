use strict;
use warnings FATAL => 'recursion';

package Daiku;
use 5.008001;
our $VERSION = '0.01';
use Scalar::Util qw/blessed/;
use Mouse;

has tasks => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { +[ ] },
);

our $CONTEXT;

sub add {
    my ($self, $task) = (shift, shift);
    push @{$self->{tasks}}, $task;
}

sub build {
    my ($self, $target) = @_;
    if (!defined $target) {
        die "Missing target";
    }

    local $CONTEXT = $self;

    my $task = $self->find_task($target);
    if ($task) {
        $task->build($target);
    } else {
        die "There is no rule to build '$target'";
    }
}

sub find_task {
    my ($self, $target) = @_;
    for my $task (@{$self->{tasks}}) {
        return $task if $task->match($target);
    }
    return undef;
}

no Mouse; __PACKAGE__->meta->make_immutable;

# This is .PHONY target.
package Daiku::Task;
use File::stat;
use Mouse;

has target => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);
has deps => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
);
has code => (
    is => 'rw',
    isa => 'CodeRef',
    default => sub { sub { } },
);

sub build {
    my ($self) = @_;

    my $rebuild = $self->_build_deps();
    if ($self->code) {
        $self->code->();
    }
    return $rebuild;
}

sub match {
    my ($self, $target) = @_;
    return 1 if $self->{target} eq $target;
    return 0;
}

sub _mtime {
    my $self = shift;
    if (!exists $self->{mtime}) {
        $self->{mtime} = do {
            my $stat = stat($self->target);
            $stat ? $stat->mtime : undef;
        };
    }
    return $self->{mtime};
}

# @return need rebuild
sub _build_deps {
    my ($self) = @_;

    my $ret = 0;
    for my $target (@{$self->deps || []}) {
        my $task = $Daiku::CONTEXT->find_task($target);
        if ($task) {
            $ret += $task->build($target);
        } else {
            if (-f $target) {
                $ret += sub {
                    my $m1 = stat($target)->mtime;
                    my $m2 = $self->_mtime;
                    return 1 unless $m2;
                    return 1 if $m2 < $m1;
                    return 0;
                }->();
            } else {
                die "I don't know to build '$target' depended by '$self->{target}'";
            }
        }
    }
    return !!$ret;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

# Suffix Rule, same as Makefile.
# like '.c.o' in Makefile.
package Daiku::SuffixRule;
use Mouse;
has src => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has dst => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has code => (
    is => 'ro',
    isa => 'CodeRef',
    default => sub { sub { } },
);

sub match {
    my ($self, $target) = @_;
    return 1 if $target =~ /\Q$self->{dst}\E$/;
    return 0;
}

sub build {
    my ($self, $target) = @_;
    (my $src = $target) =~ s/\Q$self->{dst}\E$/$self->{src}/;
    $self->code->($src, $target);
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf8

=head1 NAME

Daiku -

=head1 SYNOPSIS

    use Daiku;

    my $daiku = Daiku->new();
    $daiku->add('foo' => [qw/foo.o/] => sub {
        system "gcc -c foo foo.o";
    });
    $daiku->add('foo.o' => [qw/foo.c/] => sub {
        system "gcc -c foo.o foo.c";
    });
    $daiku->build("foo");

=head1 DESCRIPTION

Daiku is

=head1 NOTE

This module is a B<build engine>. You can write better DSL on this module.

This module doesn't detect recursion, but Perl5 can detect it.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
