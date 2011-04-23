use strict;
use warnings;
use utf8;
use Test::More;
use Fatal;
use File::stat;
use t::Util;

use Daiku;

my $guard = tmpdir();

my @ret;

my $daiku = Daiku::Engine->new();
$daiku->add(
    Daiku::File->new(
        dst  => 'a.out',
        deps => [qw/b.o c.o/],
        code => sub { link_( [qw/b.o c.o/], 'a.out' ) }
    )
);
$daiku->add(
    Daiku::SuffixRule->new(
        src => '.c',
        dst => '.o',
        code   => sub {
            my ($src, $dst) = @_;
            note "Compiling: $src => $dst";
            compile($src => $dst)
        }
    )
);
write_file("c.c", "c1");
write_file("b.c", "b1");
$daiku->build('a.out');
my $c_o_mtime1 = stat('c.o')->mtime;
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
write_file("b.c", "b2");
$daiku->build('b.o');
is(slurp('b.o'), "OBJ:b2");
is(slurp('a.out'), "OBJ:b1\nOBJ:c1");
$daiku->build('a.out');
is(slurp('a.out'), "OBJ:b2\nOBJ:c1");
my $c_o_mtime2 = stat('c.o')->mtime;
is($c_o_mtime1, $c_o_mtime2, 'is not modified.');

done_testing;


