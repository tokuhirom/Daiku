use strict;
use warnings FATAL => 'recursion';
use utf8;

package Daiku::File;
use File::stat;
use Mouse;
use Log::Minimal;
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

    $self->log("Building file: $self->{dst}");
    my $rebuild = $self->_build_deps();
    if ($rebuild || !-f $self->dst) {
        $rebuild++;
        $self->code->($self);
    } else {
        debugf("There is no reason to regenerate $self->{dst}");
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
    for my $target (@{$self->deps || []}) {
        debugf("building... %s", $target);
        my $task = $self->registry->find_task($target);
        if ($task) {
            $ret += $task->build($target);
        } else {
            if (-f $target) {
                $ret += sub {
                    my $m1 = _mtime($target);
                    return 0 unless -f $self->dst;

                    my $m2 = _mtime($self->dst);
                    debugf("m1: %s, m2: %s", $m1, $m2);

                    return 1 if $m2 < $m1;
                    return 0;
                }->();
            } else {
                die "I don't know to build '$target' depended by '$self->{target}'";
            }
        }
    }
    return $ret;
}

sub _mtime {
    my $fname = shift;
    (Time::HiRes::stat($fname))[9];
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;

