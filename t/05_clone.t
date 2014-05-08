use strict;
use warnings;
use utf8;
use Test::More;

use Daiku::Task;
use Scalar::Util qw/refaddr/;

my $task = Daiku::Task->new(name => 'a', sources => ['b']);
my $cloned = $task->clone();
isnt(refaddr($task), refaddr($cloned));
$task->name('c');
$task->sources(['d']);
is($cloned->name, 'a');
is_deeply($cloned->sources, ['b']);

done_testing;

