use strict;
use warnings;
use utf8;
use Test::More;
use Fatal;
use Daiku ();  ## Daiku without import

my $got = "";

Daiku::task("test", sub {
    $got = "ok";
});

Daiku::build("test");

is $got, "ok";

done_testing;
