use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;
use Capture::Tiny qw/capture_stdout/;

use Daiku::CLI;

subtest "invalid Daikufile" => sub {
    my $guard = tmpdir();
    write_file("Daikufile", "hoge hoget");
    eval { Daiku::CLI->new->run };
    ok $@;
};

subtest "specify Daikufile" => sub {
    my $guard = tmpdir();
    write_file("hoge.c", "hogehoge");
    write_file("myDaikufile", "rule '.o' => '.c' => sub {}");
    my $exit = Daiku::CLI->new->run("-f" => "myDaikufile", "hoge.o");
    is $exit, 0;
};

subtest "specify directory" => sub {
    my $guard = tmpdir();
    mkdir "temp";
    write_file("temp/foo", "touch");
    write_file("temp/Daikufile", "file 'hoge' => 'foo' => sub {}");
    my $exit = Daiku::CLI->new->run("-C", "temp", "hoge");
    is $exit, 0;
};

subtest "display tasks" => sub {
    my $guard = tmpdir();
    write_file("Daikufile", <<'...');
desc 'foo';
task 'footask' => sub {};

task 'bartask' => sub {};

desc 'baz';
task 'bazz' => sub {};
...

    my $stdout = capture_stdout {
        my $exit = Daiku::CLI->new->run("-T");
        is $exit, 0;
    };

    is $stdout, <<'...';
daiku footask  # foo
daiku bazz     # baz
...

};

done_testing;
