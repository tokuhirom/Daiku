use strict;
use warnings;
use utf8;

package Daiku::Role;
use Mouse::Role;

requires 'build';
requires 'match';

1;

