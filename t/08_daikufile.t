use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku::CLI;

my $guard = tmpdir();
sub clean { unlink $_ for qw(touch1 touch2) }

write_file("Daikufile", <<'...');
task "touch1" => sub {
    open my $fh, ">", "touch1" or die;
    print {$fh} "touch1";
    close $fh;
};
task "touch2" => sub {
    open my $fh, ">", "touch2" or die;
    print {$fh} "touch2";
    close $fh;
};
task "die" => sub {
    die;
};
...

my $exit;

$exit = Daiku::CLI->new->run;
is $exit, 2, 'no default target';
clean;

$exit = Daiku::CLI->new->run("touch1", "touch2");
is $exit, 0;
ok -f "touch1";
ok -f "touch2";
clean;

{
    my $warn; local $SIG{__WARN__} = sub { $warn = shift };
    $exit = Daiku::CLI->new->run("notfound");
    isnt $exit, 0;
    note $warn;
}
clean;

{
    my $warn; local $SIG{__WARN__} = sub { $warn = shift };
    $exit = Daiku::CLI->new->run("touch1", "notfound");
    isnt $exit, 0;
    ok -f "touch1";
    note $warn;
}
clean;

{
    my $warn; local $SIG{__WARN__} = sub { $warn = shift };
    $exit = Daiku::CLI->new->run("die");
    isnt $exit, 0;
    note $warn;
}
clean;

done_testing;
