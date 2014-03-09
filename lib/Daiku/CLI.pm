package Daiku::CLI;
use strict;
use warnings;
use Daiku::Daikufile;
use Getopt::Long ();

use Mouse;

has file => (
    is      => 'rw',
    isa     => 'Str',
    default => "Daikufile",
);

sub run {
    my ($self, @args) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [qw(posix_default no_ignore_case bundling)],
    );

    $p->getoptionsfromarray(
        \@args,
        "f|file=s"      => \(my $file),
        "C|directory=s" => \(my $directory),
        "h|help"        => \(my $help),
        "v|version"     => \(my $version),
    );
    if ($version) {
        require Daiku;
        printf "Daiku %s\n", Daiku->VERSION;
        exit 0;
    }
    if ($help) {
        require Pod::Usage;
        Pod::Usage::pod2usage(0);
    }

    my @target = @args;

    $self->file($file) if $file;
    if ($directory) {
        chdir $directory or die "chdir $directory failed: $!";
    }

    my $engine = Daiku::Daikufile->parse($self->file);
    if (!@target) {
        my $first_target = $engine->first_target
            or die "Missing target.\n";
        push @target, $first_target;
    }
    my $exit = 0;
    for my $target (@target) {
        eval { $engine->build($target) };
        if ($@) {
            warn "$@\n";
            $exit = 2; # like make(1)
            last;
        }
    }
    return $exit;
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;
