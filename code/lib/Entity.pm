package Entity;

use strict;
use warnings;
use 5.010;

use Mouse;

has sprites => (
    is => 'ro',
    isa => 'SDL::Surface',
    lazy => 1,
    builder => '_build_sprites',
    init_arg => undef
);

has sprite_index => (
    is => 'ro',
    isa => 'Num',
    lazy => 1,
    default => 0,
    required => 1
);

has sprite_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time,
    lazy => 1
);

has dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time
);

sub draw {
    confess shift, "should have defined `draw`";
}

sub update_index {
    confess shift, "should have defined `update_index`";
}

sub _build_sprites {
    confess shift, "should have defined `_build_sprites`";
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
