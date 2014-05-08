use strict;
use warnings FATAL => 'recursion';
use utf8;

package Daiku::File;
use File::stat;
use Mouse;
use Time::HiRes 1.9701 ();

with 'Daiku::Role';

sub build {
    my ($self) = @_;

    $self->log("Processing file: $self->{name}");
    my ($built, $need_rebuild) = $self->_build_deps();
    if ($need_rebuild || (!-f $self->name)) {
        $self->log("  Building file: $self->{name}($need_rebuild)");
        $built++;
        $self->code->($self);
    } else {
        $self->debug("There is no reason to regenerate $self->{name}");
    }
    return $built;
}

sub match {
    my ($self, $target) = @_;
    return 1 if $self->name eq $target;
    return 0;
}

# @return need rebuild
sub _build_deps {
    my ($self) = @_;

    my $built = 0;
    my $need_rebuild = 0;
    for my $target (@{$self->sources}) {
        my $task = $self->registry->find_task($target);
        if ($task) {
            $built += $task->build($target);
            if (-f $target) {
                $need_rebuild += $self->_check_need_rebuild($target);
            }
        } else {
            die "I don't know to build '$target' depended by '$self->{name}'\n";
        }
    }
    return ($built, $need_rebuild);
}

sub _check_need_rebuild {
    my ($self, $target) = @_;

    my $m1 = _mtime($target);
    return 0 unless -f $self->name;

    my $m2 = _mtime($self->name);

    return 1 if $m2 < $m1;
    return 0;
}

sub _mtime {
    my $fname = shift;
    (Time::HiRes::stat($fname))[9];
}

no Mouse; __PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Daiku::File - file creation rule

=head1 DESCRIPTION

This is a file creation rule object for Daiku

=head1 ATTRIBUTES

=over 4

=item C<< dst:Str >>

Destination file name

=item C<< deps:ArrayRef[Str] >>

This is a dependency file names.

=item C<< code:CodeRef >>

This is a callback function.

=back

=head1 METHODS

=over 4

=item C<< my $file = Daiku::File->new(%args); >>

Create a new instance of Daiku::File.

=item C<< $file->build(); >>

Build the target.

I<Return Value>: The number of built jobs.

=item C<< $file->match($name) :Bool >>

=back

