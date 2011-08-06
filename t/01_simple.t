use strict;
use warnings;
use utf8;
use Test::More;
use Cwd;
use Fatal;
use File::stat;
use t::Util;

use Daiku;

my $guard = tmpdir();

file 'a.out' => [qw/b.o c.o/] => sub {
    link_([qw/b.o c.o/], 'a.out')
};
file 'b.o' => 'b.c' => sub {
    compile 'b.c', 'b.o';
};
file 'c.o' => 'c.c' => sub {
    compile 'c.c', 'c.o';
};
write_file("c.c", "c1");
write_file("b.c", "b1");

is(build('a.out'), 3);
ok -f 'c.o', 'generated c.o';
my $c_o_mtime1 = stat('c.o')->mtime;
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
write_file("b.c", "b2"); touch(1, 'b.c');
is(build('b.o'), 1); touch(2, 'b.o');
is(slurp('b.o'), "OBJ:b2");
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
build('a.out');
is(slurp('a.out'), "OBJ:b2\nOBJ:c1");
my $c_o_mtime2 = stat('c.o')->mtime;
is($c_o_mtime1, $c_o_mtime2, 'is not modified.');

done_testing;


