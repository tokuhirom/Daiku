use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku;

my $PPP = '';

task 'all' => sub {
    my ($t, @argv) = @_;
    $PPP .= 'a';
    $PPP .= $argv[0];
};
task 'all' => sub {
    my ($t, @argv) = @_;
    $PPP .= 'b';
    $PPP .= $argv[1];
};

build 'all[xxx yyy]';

is $PPP, 'axxxbyyy';

done_testing;

