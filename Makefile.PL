use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Daiku';
all_from 'lib/Daiku.pm';

requires 'Mouse' => 0.92;
requires 'parent';
requires 'Time::HiRes' => '1.9701'; # for Time::HiRes::stat

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
