package Daiku::CLI;
use strict;
use warnings;
use Daiku::Daikufile;
use Getopt::Long 2.39 ();
use Encode qw/encode_utf8/;

use Mouse 0.92;

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
        "T|tasks"       => \(my $tasks),
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

    if ($tasks) {
        _print_tasks($engine->tasks);
        return 0;
    }

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

sub _print_tasks {
    my $tasks = shift;
    my $column_width = 1;

    my @tasks;
    for my $task (values %$tasks) {
        next unless $task->isa('Daiku::Task') && defined $task->desc;

        my $task_name = $task->dst;
        my $len = length $task_name;
        $column_width = $len if $column_width < $len;
        push @tasks, {
            name => $task_name,
            desc => $task->desc,
        };
    }

    for my $t (@tasks) {
        printf "daiku %-${column_width}s  # %s\n", encode_utf8($t->{name}), encode_utf8($t->{desc});
    }
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;
