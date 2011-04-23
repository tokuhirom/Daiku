use strict;
use warnings FATAL => 'recursion';
use utf8;

use Daiku::Task;
use Daiku::File;
use Daiku::SuffixRule;

package Daiku::Engine;
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

    local $Daiku::Engine::CONTEXT = $self;

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


1;

