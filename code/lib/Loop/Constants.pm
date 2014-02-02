package Loop::Constants;

use strict;
use warnings;
use 5.010;

use Exporter qw/import/;

our @EXPORT = qw/
    $SPRITE_W
    $SPRITE_H
    $SPRITE_HALF_W
    $SPRITE_HALF_H
    $GRAVITY
    $MOVEMENT
    $LOOK_AT_RIGHT
    $LOOK_AT_LEFT
    $LOOK_AT_ME
    $PI
    $RADIAN
/;

our $SPRITE_W = 32;
our $SPRITE_H = 32;

our $SPRITE_HALF_W = 16;
our $SPRITE_HALF_H = 16;

our $GRAVITY = 800;

our $MOVEMENT = {
    LEFT => 1,
    RIGHT => 2,
    UP => 3,
    DOWN => 4
};

our $LOOK_AT_RIGHT = 0;
our $LOOK_AT_LEFT = 1;
our $LOOK_AT_ME = 2;

our $PI = 3.14159265359;
our $RADIAN = $PI/180;

1;
