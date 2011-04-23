use strict;
use warnings FATAL => 'recursion';
use utf8;

# Suffix Rule, same as Makefile.
# like '.c.o' in Makefile.
package Daiku::SuffixRule;
use Mouse;
with 'Daiku::Role';

has src => (
    is       => 'ro',
    isa      => 'Str',
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
    (my $src = $target) =~ s/\Q$self->{dst}\E$/$self->{src}/;
    $self->code->($src, $target);
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

