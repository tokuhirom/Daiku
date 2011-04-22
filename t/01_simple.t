use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir/;
use Cwd;
use Fatal;
use File::stat;

use Daiku;

my $dir = tempdir(CLENAUP => 1);

my $cwd = Cwd::getcwd();
chdir($dir);

my @ret;

my $daiku = Daiku->new();
$daiku->add(
    Daiku::Task->new(
        target => 'a.out',
        deps   => [qw/b.o c.o/],
        code   => sub { link_([qw/b.o c.o/], 'a.out') }
    )
);
$daiku->add(
    Daiku::Task->new(
        target => 'b.o',
        code   => sub { compile('b.c' => 'b.o') }
    )
);
$daiku->add(
    Daiku::Task->new(
        target => 'c.o',
        deps   => [qw/c.c/],
        code   => sub { compile('c.c' => 'c.o') }
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

chdir($cwd); # back to orig dir

done_testing; exit;

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname;
    do { local $/; <$fh> };
}

sub link_ {
    my ($srcs, $dst) = @_;
    write_file( $dst, join( "\n", map { slurp($_) } @$srcs ) );
}

sub compile {
    my ($src, $dst) = @_;
    my $content = "OBJ:" . slurp($src);
    write_file($dst, $content);
}

sub write_file {
    my ($fname, $content) = @_;
    open my $fh, '>', $fname or die;
    print {$fh} $content;
}

