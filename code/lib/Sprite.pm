package Sprite;

use strict;
use warnings;
use 5.010;

use Loop::Constants;
use Mouse;

has img => (
    is => 'ro',
    isa => 'SDL::Surface',
    lazy => 1,
    builder => '_build_img'
);

##the "world" positions of the center of sprite to be rendered to
has ['x', 'y'] => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

##the updated "world" positions of the center of sprite to be rendered to
has ['newx', 'newy'] => (
    is => 'rw',
    isa => 'Num'
);

##
has ['w', 'h'] => (
    is => 'ro',
    isa => 'Int',
    required => 1
);

##
has ['half_w', 'half_h'] => (
    is => 'rw',
    isa => 'Int'
);

#sprite physical dimensions (chunk) to be rendered from [upper_left_x, upper_left_y, width_x, height_y]
has render_rect => (
    is => 'rw',
    isa => 'ArrayRef[Int]',
    default => sub { [0, 0, $SPRITE_W, $SPRITE_H] }
);

has cur_render_rect => (
    is => 'rw',
    isa => 'ArrayRef[Int]',
    default => sub { [0, 0, $SPRITE_W, $SPRITE_H] }
);

sub update_index {
    confess shift, " should have defined `update_index`";
}

sub update_pos {
    my ($self, $x, $y) = @_;
    $self->x($x);
    $self->y($y);
}

sub draw {
    confess shift, " should have defined `draw`";
}

sub _build_img {
    confess shift, " should have defined `_build_img`";
}

sub BUILD {
    my ($self) = @_;

    $self->half_w(int($self->w/2));
    $self->half_h(int($self->h/2));
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
