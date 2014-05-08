use strict;
use warnings FATAL => 'recursion';
use utf8;

use Daiku::Task;
use Daiku::File;
use Daiku::SuffixRule;

use Parse::CommandLine ();
use Tie::IxHash;

package Daiku::Registry;
use Mouse;

has tasks => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { tie my %h, "Tie::IxHash"; \%h },
);

has temporary_desc => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'clear_temporary_desc',
);

has namespaces => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub register {
    my ($self, $task) = (shift, shift);
    my $orig = $self->find_task($task->dst);
    $task->merge($orig) if $orig;
    $self->tasks->{$task->dst} = $task;
    $task->registry($self);
}

sub build {
    my ($self, $target) = @_;
    if (!defined $target) {
        die "Missing target\n";
    }

    # parsing 'task_name[arg1 arg2]'
    ($target, my $argument) = $target =~ /\A([^\[]+)(?:\[(.*)\])?\z/ms;
    my @args;
       @args = Parse::CommandLine::parse_command_line($argument) if defined $argument;

    my $task = $self->find_task($target);
    if ($task) {
        return $task->build($target, @args);
    } else {
        die "There is no rule to build '$target'\n";
    }
}

sub find_task {
    my ($self, $target) = @_;
    for my $task (values %{$self->{tasks}}) {
        return $task if $task->match($target);
    }
    if ( -f $target ) {
        return Daiku::File->new( dst => $target );
    }
    return undef;
}

sub first_target {
    my $self = shift;
    my ($target) = keys %{$self->{tasks}};
    return $target;
}

no Mouse; __PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Daiku::Registry - Daiku's engine

=head1 SYNOPSIS

    use autodie;

    my $daiku = Daiku->new();
    $daiku->register( Daiku::Task->new( dst => 'all', deps => [qw/a.out/] ) );
    $daiku->register(
        Daiku::File->new(
            dst  => 'a.out',
            deps => [qw/b.o c.o/],
            code => sub {
                my $task = shift;
                system "cc -o @{[ $task->dst ]} @{[ join ' ', @{$task->src} ]}";
            }
        )
    );
    $daiku->register(
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

This is a engine of Daiku. This module is a registrar of Daiku.

=head1 METHODS

=over 4

=item C<< my $daiku = Daiku::Registry->new(); >>

Create new instance of Daiku::Registry.

=item C<< $daiku->register($task : Daiku::Task|Daiku::SuffixRule|Daiku::File) : void >>

Register a task for Daiku::Registry.

=item C<< $daiku->build($target : Str) : void >>

Build a C<< $target >>.

=back

=head1 AUTHOR

Tokuhiro Matsuno

