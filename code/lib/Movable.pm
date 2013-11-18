package Movable;

use strict;
use warnings;
use 5.010;

use Mouse;

#new attribute
has look_sprites => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Num]]',
    default => sub {[ [0, 32*2, 32, 32], [0, 32, 32, 32], [0, 0, 32, 32] ]}
);

#new attribute
has velocity => (
    is => 'rw',
    isa => 'Num',
    default => 6,
    required => 1
);

#new attribute
has step_x => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

#new attribute
has step_x_speed => (
    is => 'rw',
    isa => 'Num',
    default => 4
);

#new attribute
has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[0, 100, 32, 32]}
);

#new attribute
sub get_pos_x {
    return shift->pos->[0];
}

#new attribute
sub get_pos_y {
    return shift->pos->[1];
}

#new attribute
sub update_index {
    confess shift, " should have defined `update_index`";
}

#new attribute
sub update_pos {
    confess shift, " should have defined `update_pos`";
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
