use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku;

my $guard = tmpdir();

task task1 => sub {
    my ($task, @args) = @_;

    is_deeply \@args, [qw/hoge fuga --bar=baz/];
};

build 'task1[hoge "fuga" --bar="baz"]';

done_testing;
