use strict;
use warnings FATAL => 'recursion';
use utf8;

# This is .PHONY target.
package Daiku::Task;
use File::stat;
use Mouse;

with 'Daiku::Role';

has dst => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has deps => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { +[ ] },
);
has code => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
);

# @return affected things
sub build {
    my ($self) = @_;
    $self->log("Building Task: $self->{dst}");

    my $built = $self->_build_deps();

    $self->code->($self);
    $built++;

    return $built;
}

sub match {
    my ($self, $target) = @_;
    return 1 if $self->dst eq $target;
    return 0;
}

# @return the number of built tasks
sub _build_deps {
    my ($self) = @_;

    my $ret = 0;
    for my $target (@{$self->deps}) {
        my $task = $self->registry->find_task($target);
        if ($task) {
            $ret += $task->build($target);
        } else {
            die "I don't know to build '$target' depended by '$self->{dst}'";
        }
    }
    return $ret;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

