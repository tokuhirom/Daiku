use strict;
use warnings;
use utf8;
use Test::More;

use t::Util;
use Daiku::CLI;

my $guard = tmpdir();

write_file("Daikufile", <<'...');
task touch1 => sub {
    open my $fh, ">", "touch1" or die;
    print {$fh} "touch1";
    close $fh;
};
task default => sub {
    open my $fh, ">", "touch2" or die;
    print {$fh} "touch2";
    close $fh;
};
...

my $exit = Daiku::CLI->new->run;
is $exit, 0;
ok ! -f "touch1";
ok -f "touch2";

done_testing;
