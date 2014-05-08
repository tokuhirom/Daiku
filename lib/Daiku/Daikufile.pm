package Daiku::Daikufile;
use strict;
use warnings;
use Mouse;

my $file_id = 1;

sub parse {
    my ($self, $file) = @_;

    my $code = do {
        open my $fh, "<", $file or die "open $file failed: $!\n";
        local $/; <$fh>;
    };

    # code taken from Module::CPANfile::Environment
    my ($engine, $err);
    {
        local $@;
        $file_id++;
        $engine = eval <<"EVAL"; ## no critic
package Daiku::Daikufile::Sandbox$file_id;
use Daiku;
use strict;
use warnings;
use utf8;
use autodie;

# line 1 "$file"
$code;
engine;
EVAL
        $err = $@;
    }

    if ($err) { die "Parsing $file failed: $err\n" }

    return $engine;
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;
