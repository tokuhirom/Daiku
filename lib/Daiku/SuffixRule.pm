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

sub match {
    my ($self, $target) = @_;
    return 1 if $target =~ /\Q$self->{dst}\E$/;
    return 0;
}

sub build {
    my ($self, $target) = @_;
    $self->log("Building SuffixRule: $target");
    my ($built, $need_rebuild, $sources) = $self->_build_deps($target);

    if ($need_rebuild || !-f $target) {
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

    my @srcs = ($self->src);
       @srcs = @{ $srcs[0] } if (ref($srcs[0]) || '') eq 'ARRAY';
    for my $src (@srcs) {
        (my $source = $target) =~ s/\Q$self->{dst}\E$/$src/;
        push @sources, $source;
        my $task = $self->registry->find_task($source);
        if ($task) {
            $built += $task->build($source);
            if (-f $target && -f $source) {
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

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

