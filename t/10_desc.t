use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku;

my $guard = tmpdir();

desc 'ttt';
task task1 => sub { };

task task2 => sub { };

desc 'sss';
task task3 => sub { };

is engine->find_task('task1')->desc, 'ttt';
ok !engine->find_task('task2')->desc;
is engine->find_task('task3')->desc, 'sss';

done_testing;
