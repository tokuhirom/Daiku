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

my @ret;

my $daiku = Daiku::Registry->new();
$daiku->register(
    Daiku::File->new(
        dst => 'a.out',
        deps   => [qw/b.o c.o/],
        code   => sub { link_([qw/b.o c.o/], 'a.out') }
    )
);
$daiku->register(
    Daiku::File->new(
        dst  => 'b.o',
        deps => ['b.c'],
        code => sub { compile( 'b.c' => 'b.o' ) }
    )
);
$daiku->register(
    Daiku::File->new(
        dst => 'c.o',
        deps   => [qw/c.c/],
        code   => sub { compile('c.c' => 'c.o') }
    )
);
write_file("c.c", "c1");
write_file("b.c", "b1");
is($daiku->build('a.out'), 3);
my $c_o_mtime1 = stat('c.o')->mtime;
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
write_file("b.c", "b2");
touch(1, 'b.c');
is($daiku->build('b.o'), 2);
is(slurp('b.o'), "OBJ:b2");
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
$daiku->build('a.out');
is(slurp('a.out'), "OBJ:b2\nOBJ:c1");
my $c_o_mtime2 = stat('c.o')->mtime;
is($c_o_mtime1, $c_o_mtime2, 'is not modified.');

done_testing;


