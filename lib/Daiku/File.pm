use strict;
use warnings FATAL => 'recursion';
use utf8;

package Daiku::File;
use File::stat;
use Mouse;

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

    my $rebuild = $self->_build_deps();
    $self->code->();
    return $rebuild;
}

sub match {
    my ($self, $target) = @_;
    return 1 if $self->dst eq $target;
    return 0;
}

sub _mtime {
    my $self = shift;

    if (!exists $self->{mtime}) {
        $self->{mtime} = do {
            my $stat = stat($self->dst);
            $stat ? $stat->mtime : undef;
        };
    }
    return $self->{mtime};
}

# @return need rebuild
sub _build_deps {
    my ($self) = @_;

    my $ret = 0;
    for my $target (@{$self->deps || []}) {
        my $task = $Daiku::Engine::CONTEXT->find_task($target);
        if ($task) {
            $ret += $task->build($target);
        } else {
            if (-f $target) {
                $ret += sub {
                    my $m1 = stat($target)->mtime;
                    my $m2 = $self->_mtime;

                    return 1 unless $m2;
                    return 1 if $m2 < $m1;
                    return 0;
                }->();
            } else {
                die "I don't know to build '$target' depended by '$self->{target}'";
            }
        }
    }
    return !!$ret;
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;

