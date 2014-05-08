use strict;
use warnings FATAL => 'recursion';
use utf8;

# Suffix Rule, same as Makefile.
# like '.c.o' in Makefile.
package Daiku::SuffixRule;
use Mouse;
with 'Daiku::Role';

use File::stat;

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
    $self->log("Building SuffixRule: $target");
    (my $src = $target) =~ s/\Q$self->{dst}\E$/$self->{src}/;
    my $need_rebuild = sub {
        return 1 unless -f $target;
        die "Missing source file '$src' to build '$target'\n" unless -f $src;
        if (stat($target)->mtime < stat($src)->mtime) {
            return 1;
        } else {
            return 0;
        }
    }->();
    if ($need_rebuild) {
        $self->log("  Building rule: $target");
        $self->code->($self, $target, $src);
        return 1;
    } else {
        $self->log("  nop rule: $target");
        return 0;
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

