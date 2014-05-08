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
has name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has sources => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { +[ ] },
);
has code => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub { } },
);
sub source {
    my $self = shift;
    return @{ $self->sources } ? $self->sources->[0] : undef;
}

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

    if ($self->meta->has_attribute('source_rules')) {
        unshift @{$self->source_rules}, @{$task->source_rules};
    } else {
        unshift @{$self->sources}, @{$task->sources};
    }

    my $orig_code = $self->code();
    my $other_code = $task->code();
    $self->code(sub {
        $other_code->(@_);
        $orig_code->(@_);
    });
}

1;

