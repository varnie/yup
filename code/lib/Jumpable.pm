package Jumpable;

use strict;
use warnings;
use 5.010;

use Mouse;

#new attribute
has jump_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time
);

#new attribute
has jumping => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
