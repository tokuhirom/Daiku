use strict;
use warnings FATAL => 'recursion';
use utf8;

# Suffix Rule, same as Makefile.
# like '.c.o' in Makefile.
package Daiku::SuffixRule;
use Time::HiRes 1.9701 ();
use Mouse;
with 'Daiku::Role';

has src => (
    is       => 'ro',
    required => 1,
);
has dst => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has code => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        sub { }
    },
);

has _dst_regex => (
    is      => 'ro',
    isa     => 'Regexp',
    default => sub {
        my $self = shift;
        my $dst = $self->dst;
        ref $dst && ref $dst eq 'Regexp' ? $dst : qr/\Q$dst\E$/;
    },
);

sub match {
    my ($self, $target) = @_;
    $target =~ $self->_dst_regex;
}

sub build {
    my ($self, $target) = @_;
    $self->log("Building SuffixRule: $target");
    my ($built, $need_rebuild, $sources) = $self->_build_deps($target);

    if ($need_rebuild || !-e $target) {
        $built++;
        $self->code->($self, $target, @$sources);
    } else {
        $self->debug("There is no reason to regenerate $target");
    }
    return $built;
}

sub _build_deps {
    my ($self, $target) = @_;

    my $built = 0;
    my $need_rebuild = 0;
    my @sources;
    for my $src (_flatten($self->src)) {
        if ( (ref($src) || '') eq 'CODE') {
            my @add_sources = _flatten($src->($target));
            push @sources, @add_sources;
        }
        else {
            (my $source = $target) =~ s/@{[$self->_dst_regex]}/$src/;
            push @sources, $source;
        }
    }

    for my $source (@sources) {
        my $task = $self->registry->find_task($source);
        if ($task) {
            $built += $task->build($source);
            if (-e $target && -e $source) {
                $need_rebuild += 1 if _mtime($target) < _mtime($source);
            }
        } else {
            die "I don't know to build '$source' depended by '$target'\n";
        }
    }

    return ($built, $need_rebuild, \@sources);
}

sub _mtime {
    my $fname = shift;
    (Time::HiRes::stat($fname))[9];
}

sub _flatten {
    map { ref $_ && ref $_ eq 'ARRAY' ? _flatten(@{$_}) : $_ } @_;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

