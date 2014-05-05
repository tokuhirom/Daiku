use strict;
use warnings;
use utf8;
use Test::More;

use t::Util;
use Daiku;

use Capture::Tiny qw/capture_stdout/;

my $stdout = capture_stdout { sh qq{$^X -e 'print "11"'} };
is $stdout, "11";

eval { sh $^X, '-e', 'die'; };
ok $@;

done_testing;
