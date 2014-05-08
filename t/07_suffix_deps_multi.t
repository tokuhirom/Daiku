use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

use Daiku;

my $guard = tmpdir();

file 'a.out' => ['b.o', 'c.o'] => sub {
    link_(['b.o', 'c.o'] => 'a.out');
};

rule '.o' => ['.h', '.c'] => sub {
    my ($task, $dst, $srcs) = @_;
    my ($h, $c) = @{ $srcs };
    write_file( $dst, slurp($h) . ";" . slurp($c) );
};
write_file('b.c' => 'bc');
write_file('b.h' => 'bh');
write_file('c.c' => 'cc');
write_file('c.h' => 'ch');

is(build('b.o'), 1);
ok(-f 'b.o');
is(build('b.o'), 0);
is(slurp('b.o'), 'bh;bc');

unlink 'b.o';
is(build('a.out'), 3);
ok(-f 'a.out');
is(build('a.out'), 0);
is(slurp('a.out'), "bh;bc\nch;cc");

write_file('b.c' => 'bc+'); touch(-2, 'b.o'); touch(-2, 'a.out');
is(build('a.out'), 2); touch(+3, 'a.out'); touch(+2, 'b.o');
is(slurp('a.out'), "bh;bc+\nch;cc");
is(build('a.out'), 0, 'a.out');

done_testing;

