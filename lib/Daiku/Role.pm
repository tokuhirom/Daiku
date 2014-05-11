use strict;
use warnings;
use utf8;

package Daiku::Role;
use Mouse::Role;
use Scalar::Util qw/blessed/;
use Carp ();

requires 'build';
requires 'match';

has registry => (
    is       => 'rw',
    isa      => 'Maybe[Daiku::Registry]',
    weak_ref => 1,
);

sub clone {
    my $self = shift;

    my %args;
    for my $attr ($self->meta->get_attribute_list) {
        $args{$attr} = $self->$attr;
    }
    return $self->meta->name->new(%args);
}

sub log {
    my ($class, @msg) = @_;
    print "[LOG] @msg\n";
}

sub debug {
    my ($class, @msg) = @_;
    print "[LOG][DBG] @msg\n" if $ENV{DAIKU_DEBUG};
}

sub merge {
    my ($self, $task) = @_;
    return unless $task;

    Carp::croak("Cannot merge defferent type task: $task")
      if blessed($self) ne blessed($task);

    if ($self->can('deps')) {
        unshift @{$self->deps}, @{$task->deps};
    }

    my $orig_code = $self->code();
    my $other_code = $task->code();
    $self->code(sub {
        $other_code->(@_);
        $orig_code->(@_);
    });
}

1;

