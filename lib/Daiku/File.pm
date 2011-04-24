use strict;
use warnings FATAL => 'recursion';
use utf8;

package Daiku::File;
use File::stat;
use Mouse;
use Time::HiRes ();

with 'Daiku::Role';

has dst => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has deps => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub { +[] },
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

    $self->log("Processing file: $self->{dst}");
    my ($built, $need_rebuild) = $self->_build_deps();
    if ($need_rebuild || (!-f $self->dst)) {
        $self->log("  Building file: $self->{dst}($need_rebuild)");
        $built++;
        $self->code->($self);
    } else {
        $self->debug("There is no reason to regenerate $self->{dst}");
    }
    return $built;
}

sub match {
    my ($self, $target) = @_;
    return 1 if $self->dst eq $target;
    return 0;
}

# @return need rebuild
sub _build_deps {
    my ($self) = @_;

    my $built = 0;
    my $need_rebuild = 0;
    for my $target (@{$self->deps || []}) {
        my $task = $self->registry->find_task($target);
        if ($task) {
            $built += $task->build($target);
            if (-f $target) {
                $need_rebuild += $self->_check_need_rebuild($target);
            }
        } else {
            die "I don't know to build '$target' depended by '$self->{dst}'";
        }
    }
    return ($built, $need_rebuild);
}

sub _check_need_rebuild {
    my ($self, $target) = @_;

    my $m1 = _mtime($target);
    return 0 unless -f $self->dst;

    my $m2 = _mtime($self->dst);

    return 1 if $m2 < $m1;
    return 0;
}

sub _mtime {
    my $fname = shift;
    (Time::HiRes::stat($fname))[9];
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Daiku::File - file creation rule

=head1 DESCRIPTION

This is a file creation rule object for Daiku

=head1 METHODS

=over 4

=back

