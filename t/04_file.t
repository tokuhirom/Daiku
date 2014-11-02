use strict;
use warnings;
use utf8;
use Test::More;
use Daiku;
use t::Util;

my $guard = tmpdir();

task 'all' => 'a.out';
task 'clean' => sub {
    unlink $_ for qw/a.out b.o c.o/;
};
file 'a.out' => [qw/b.o c.o/] => sub {
    my ($file) = @_;
    isa_ok $file, "Daiku::File";
    link_( [qw/b.o c.o/], 'a.out' )
};
file 'b.o' => 'b.c' => sub {
    compile('b.c' => 'b.o');
};
file 'c.o' => 'c.c' => sub {
    compile('c.c' => 'c.o');
};
write_file("c.c", "c1");
write_file("b.c", "b1");

is(build('b.o'), 1);
is(build('b.o'), 0, 'b.o');
is(build('a.out'), 2);
is(build('a.out'), 0);
is(build('clean'), 1);
is(build('all'), 4);
is(build('all'), 1);

done_testing;

