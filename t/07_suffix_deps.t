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
rule '.o' => '.c' => sub {
	my ($src, $dst) = @_;
	compile($src => $dst);
};
write_file('b.c' => 'b1');
write_file('c.c' => 'c1');

# build
is(build('a.out'), 3);
ok(-f 'a.out');
is(build('a.out'), 0, 'a.out');
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
write_file('b.c' => 'b2'); touch(-2, 'b.o'); touch(-2, 'a.out');
is(build('a.out'), 2); touch(+3, 'a.out'); touch(+2, 'b.o');
is(slurp('a.out'), "OBJ:b2\nOBJ:c1");
is(build('a.out'), 0, 'a.out');

done_testing;

