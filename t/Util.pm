use strict;
use warnings;
use utf8;

package t::Util;
use parent qw/Exporter/;

our @EXPORT = qw/slurp link_ compile write_file tmpdir/;

sub tmpdir() {
	t::Util::TmpDir->new();
}

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname or die "Cannot open file: $fname: $!";
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

package t::Util::TmpDir;
use File::Temp qw/tempdir/;
use Cwd;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{cwd} = Cwd::getcwd();
	$self->{dir} = tempdir(CLENAUP => 1);
	chdir($self->{dir}) or die "Cannot chdir";
	return $self;
}

sub DESTROY {
	my ($self) = @_;
	chdir($self->{cwd});
	delete $self->{$_} for keys %$self;
}

1;

