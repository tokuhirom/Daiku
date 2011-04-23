use strict;
use warnings;
use utf8;
use Test::More;

use Daiku::Task;
use Scalar::Util qw/refaddr/;

my $task = Daiku::Task->new(dst => 'a', deps => ['b']);
my $cloned = $task->clone();
isnt(refaddr($task), refaddr($cloned));
$task->dst('c');
$task->deps(['d']);
is($cloned->dst, 'a');
is_deeply($cloned->deps, ['b']);

done_testing;

