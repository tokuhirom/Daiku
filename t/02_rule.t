use strict;
use warnings;
use utf8;
use Test::More;
use Fatal;
use File::stat;
use t::Util;

use Daiku;

my $guard = tmpdir();

file 'a.out' => [qw/b.o c.o/] => sub {
    link_( [qw/b.o c.o/], 'a.out' )
};
rule '.o' => '.c' => sub {
    my ($task, $dst, $src) = @_;
    note "Compiling: $src => $dst";
    compile($src => $dst)
};

write_file("c.c", "c1");
write_file("b.c", "b1");
is(build('a.out'), 3);
my $c_o_mtime1 = stat('c.o')->mtime;
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
write_file("b.c", "b2"); touch(-1, 'b.o'); touch(-2, 'a.out');
is(build('b.o'), 1);
is(slurp('b.o'), "OBJ:b2");
is(slurp('a.out'), "OBJ:b1\nOBJ:c1"); touch(+1, 'b.o');
is(build('a.out'), 1);
is(slurp('a.out'), "OBJ:b2\nOBJ:c1", 'a.out');
my $c_o_mtime2 = stat('c.o')->mtime;
is($c_o_mtime1, $c_o_mtime2, 'is not modified.');

done_testing;

