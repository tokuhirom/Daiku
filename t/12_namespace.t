use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku;

namespace n1 => sub {
    desc 't1';
    task task1 => sub { };

    namespace n2 => sub {
        desc 't2';
        task task2 => sub { };
    };
};

desc 't3';
task task3 => sub { };

###

is_deeply [keys %{ engine->tasks }], [qw/n1:task1 n1:n2:task2 task3/];
is engine->find_task('n1:task1')->desc, 't1';
is engine->find_task('n1:n2:task2')->desc, 't2';
is engine->find_task('task3')->desc, 't3';

done_testing;
