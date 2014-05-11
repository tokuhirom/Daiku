use strict;
use warnings;
use utf8;
use Test::More;

use t::Util;

use Daiku;

my $guard = tmpdir();


rule '.o' => sub {
    my ($file) = @_;
    $file =~ s/\.o$//;
    ("$file.h", "$file.c");
} => sub {
    my ($task, $dst, @srcs) = @_;

    my $content = join ';', map { slurp($_) } @srcs;
    write_file($dst, $content);
};

rule '.p' => sub {
    my ($file) = @_;
    $file =~ s/\.p$//;
    "$file.h";
} => sub {
    my ($task, $dst, @srcs) = @_;

    my $content = join ';', map { slurp($_) } @srcs;
    write_file($dst, $content);
};

rule '.q' => sub {
    my ($file) = @_;
    $file =~ s/\.q$//;
    ["$file.h", "$file.c"];
} => sub {
    my ($task, $dst, @srcs) = @_;

    my $content = join ';', map { slurp($_) } @srcs;
    write_file($dst, $content);
};

rule '.r' => [sub {
    my ($file) = @_;
    $file =~ s/\.r$//;
    ["$file.h", "$file.c"];
}] => sub {
    my ($task, $dst, @srcs) = @_;

    my $content = join ';', map { slurp($_) } @srcs;
    write_file($dst, $content);
};

write_file('b.c' => 'bc');
write_file('b.h' => 'bh');

subtest 'subref returns list' => sub {
    is(build('b.o'), 1);
    ok(-f 'b.o');
    is(build('b.o'), 0);
    is(slurp('b.o'), 'bh;bc');
};

subtest 'subref returns single scalar' => sub {
    is(build('b.p'), 1);
    ok(-f 'b.p');
    is(build('b.p'), 0);
    is(slurp('b.p'), 'bh');
};

subtest 'subref returns array ref' => sub {
    is(build('b.q'), 1);
    ok(-f 'b.q');
    is(build('b.q'), 0);
    is(slurp('b.q'), 'bh;bc');
};

subtest 'subref in array ref' => sub {
    is(build('b.r'), 1);
    ok(-f 'b.r');
    is(build('b.r'), 0);
    is(slurp('b.r'), 'bh;bc');
};

done_testing;
