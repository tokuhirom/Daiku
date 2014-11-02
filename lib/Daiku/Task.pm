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
has desc => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

# @return affected things
sub build {
    my ($self, $target, @args) = @_;
    $self->log("Building Task: $self->{dst}");

    my $built = $self->_build_deps();

    $self->code->($self, @args);
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
            die "I don't know to build '$target' depended by '$self->{dst}'\n";
        }
    }
    return $ret;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Daiku::Task - Task

=head1 DESCRIPTION

This is a .PHONY task object.

=head1 ATTRIBUTES

=over 4

=item C<< dst:Str >>

Destination task name.

=item C<< deps:ArrayRef[Str] >>

Dependency task names.

=item C<< code:CodeRef >>

Callback function.

=item C<< desc:Str >>

Description of this task.

=back

=head1 METHODS

=over 4

=item C<< my $task = Daiku::Task->new(%args); >>

Create a new instance of L<Daiku::Task>. Specify above attributes in C<%args>.

=item C<< $task->build(); >>

Build the target.

I<Return Value>: The number of built jobs.

=item C<< my $clone = $task->clone(); >>

Create and return a clone of this C<$task>.

=back
