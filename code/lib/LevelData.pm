package LevelData;

use strict;
use warnings;
use 5.010;

use Mouse;

has ['w', 'h'] => (
    is => 'ro',
    isa => 'Int',
    required => 1
);

has ch => (
    is => 'ro',
    isa => 'Character',
    required => 1
);

has 'blocks' => (
    is => 'ro',
    isa => 'HashRef[Int]',
    required => 1
);

has 'riding_blocks' => (
    is => 'ro',
    isa => 'ArrayRef[RidingBlock]',
    required => 1
);

has animated_sprites => (
    is => 'ro',
    isa => 'HashRef[AnimatedSprite]',
    required => 1
);

has bad_guys => (
    is => 'ro',
    isa => 'ArrayRef[BadGuy]',
    required => 1
);

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
