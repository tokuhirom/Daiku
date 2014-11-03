use strict;
use warnings;
use utf8;
use Test::More;
use Fatal;
use Daiku;

sub to_count_hash {
    my (@list) = @_;
    my %count_hash = ();
    $count_hash{$_}++ for @list;
    return \%count_hash;
}

my @got_tasks = ();

## multi deps, without callback
task "all" => [qw(t1 t2 t3)];

## multi deps, with callback
task "t1" => [qw(t4 t5)] => sub {
    my ($t) = @_;
    is $t->dst, "t1";
    is_deeply $t->deps, [qw(t4 t5)];
    push @got_tasks, "t1";
};

## leaf tasks
foreach my $name (qw(t2 t3 t4 t5)) {
    task $name, sub {
        my ($t) = @_;
        is $t->dst, $name;
        is_deeply $t->deps, [];
        push @got_tasks, $name;
    };
}

is build("all"), 6;
is_deeply(
    to_count_hash(@got_tasks),
    to_count_hash(qw(t1 t2 t3 t4 t5)),
    "executed tasks OK (don't care their order)"
);

my $got_tasks_str = join("", @got_tasks);
cmp_ok index($got_tasks_str, "t1"), ">", index($got_tasks_str, "t4"), "t1 should be after t4";
cmp_ok index($got_tasks_str, "t1"), ">", index($got_tasks_str, "t5"), "t1 should be after t5";

done_testing;
