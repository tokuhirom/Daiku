use strict;
use warnings;
use utf8;

package Daiku::Role;
use Mouse::Role;

requires 'build';
requires 'match';

sub clone {
    my $self = shift;

    my %args;
    for my $attr ($self->meta->get_attribute_list) {
        $args{$attr} = $self->$attr;
    }
    return $self->meta->name->new(%args);
}

sub log {
    my ($class, @msg) = @_;
    print "[LOG] @msg\n";
}

1;

