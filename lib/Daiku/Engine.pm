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

__END__

=head1 NAME

Daiku::Engine - Daiku's engine

=head1 SYNOPSIS

	use autodie;

    my $daiku = Daiku->new();
    $daiku->add( Daiku::Task->new( dst => 'all', deps => [qw/a.out/] ) );
    $daiku->add(
        Daiku::File->new(
            dst  => 'a.out',
            deps => [qw/b.o c.o/],
            code => sub {
                my $task = shift;
                system "cc -o @{[ $task->dst ]} @{[ join ' ', @{$task->src} ]}";
            }
        )
    );
    $daiku->add(
        Daiku::SuffixRule->new(
            src  => '.c',
            dst  => '.o',
            code => sub {
                my ( $src, $dst ) = @_;
                system "cc -c $dst $src";
            }
        )
    );
    $daiku->build('all');

=head1 DESCRIPTION

This is a engine of Daiku. This module is a registrar of daiku.

=head1 METHODS

=over 4

=item my $daiku = Daiku::Engine->new();

Create new instance of Daiku::Engine.

=item $daiku->add($task : Daiku::Task|Daiku::SuffixRule|Daiku::File) : void

Register a task for Daiku::Engine.

=item $daiku->build($target : Str) : void

Build a C<< $target >>.

=back

=head1 AUTHOR

Tokuhiro Matsuno

