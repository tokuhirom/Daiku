use strict;
use warnings FATAL => 'recursion';

package Daiku;
use 5.008001;
our $VERSION = '0.01';
use Scalar::Util qw/blessed/;

our $CONTEXT;

sub new {
    my $class = shift;
    bless { tasks => [], }, $class;
}

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
        $task->build();
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

# TODO split file
package Daiku::Task;
use File::stat;
use Class::Accessor::Lite 0.05 (
    rw => [
        qw(
          target
          deps
          code
          phoeny
          )
    ]
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    return bless {%args}, $class;
}

sub build {
    my ($self) = @_;

    my $rebuild = $self->build_deps();
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

sub mtime {
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
sub build_deps {
    my ($self) = @_;

    my $ret = 0;
    for my $target (@{$self->deps || []}) {
        my $task = $Daiku::CONTEXT->find_task($target);
        if ($task) {
            $ret += $task->build();
        } else {
            if (-f $target) {
                if (stat($target)->mtime > $self->mtime) {
                    $ret++; # require rebuild
                }
            } else {
                die "I don't know to build '$target' depended by '$self->{target}'";
            }
        }
    }
    return !!$ret;
}

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
