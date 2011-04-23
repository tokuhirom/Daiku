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

sub build {
    my ($self) = @_;
    $self->log("Building Task: $self->{dst}");

    my $rebuild = $self->_build_deps();
    if ($self->code) {
        $self->code->($self);
    }
    return $rebuild;
}

sub match {
    my ($self, $target) = @_;
    return 1 if $self->dst eq $target;
    return 0;
}

# @return need rebuild
sub _build_deps {
    my ($self) = @_;

    my $ret = 0;
    for my $target (@{$self->deps}) {
        my $task = $Daiku::Registry::CONTEXT->find_task($target);
        if ($task) {
            $ret += $task->build($target);
        } else {
            if (-f $target) {
                $ret += 1;
            } else {
                die "I don't know to build '$target' depended by '$self->{dst}'";
            }
        }
    }
    return !!$ret;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

