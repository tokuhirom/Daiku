use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku;

my $FFF = '';
my $PPP = '';

task 'all' => 'foo' => sub {
    $PPP .= 'a';
};
task 'all' => 'bar' => sub {
    $PPP .= 'b';
};
task 'foo' => sub { $FFF .= "foo " };
task 'bar' => sub { $FFF .= "bar " };

is( join( ',', @{ engine()->find_task('all')->deps } ), 'foo,bar' );

build 'all';

is $FFF, 'foo bar ';
is $PPP, 'ab';

done_testing;

