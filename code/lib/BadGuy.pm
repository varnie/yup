package BadGuy;

use strict;
use warnings;
use 5.010;

use Mouse;
use TextureManager;

use CollisionDetector;

use SDL::Video;
use Entity;
use Movable;
use Jumpable;
extends 'Entity', 'Movable', 'Jumpable';

use constant {
    LOOK_AT_RIGHT => 0,
    LOOK_AT_LEFT => 1,
    LOOK_AT_ME => 2
};

#override Movable attribute
has look_sprites => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Num]]',
    default => sub {[ [32*6, 32*2, 32, 32], [0, 32, 32, 32], [32*6, 0, 32, 32] ]}
);

#new attribute
has sprites_overlap => (
    is => 'ro',
    isa => 'SDL::Surface',
    lazy => 1,
    builder => '_build_sprites_overlap',
    init_arg => undef
);

#new attribute
has screen_w => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

#new attribute
has screen_h => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

#new attribute
has map_width => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

#new attribute
has map_height => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

#new attribute
has map_ref => (
    is => 'rw',
    isa => 'HashRef[Num]',
    required => 1
);

#override Entity method
sub calc_map_pos {
    my ($self, $map_offset_x, $map_offset_y) = @_;
    my ($pos_x, $pos_y) = @{$self->pos}[0..1];

    @{$self->map_pos}[0..1] = ($pos_x-$map_offset_x, $pos_y-$map_offset_y);
    return $self->map_pos;
}

#override
sub draw {
    my ($self, $display_surface_ref, $map_offset_x, $map_offset_y) = @_;
    my $src = do {
        if ($self->step_x > 0) {
            my $pattern = $self->look_sprites->[LOOK_AT_RIGHT];
            $pattern->[0] = 32*6+32*$self->sprite_index;
            $pattern;
        } elsif ($self->step_x < 0) {
            my $pattern = $self->look_sprites->[LOOK_AT_LEFT];
            $pattern->[0] = 32*6+32*$self->sprite_index;
            $pattern;
        } else {
            $self->look_sprites->[LOOK_AT_ME];
        }
    };

    my $bounds = CollisionDetector->instance->strict_intersect_bounds($self->pos);
    if ($bounds) {
        my ($bounds_x, $bounds_y, $bounds_width, $bounds_height) = @{$bounds};

        my $map_pos = $self->calc_map_pos($map_offset_x, $map_offset_y);
        my ($ch_pos_x, $ch_pos_y) = @{$self->pos}[0..1];

        if ($bounds_x == $ch_pos_x && $bounds_y == $ch_pos_y &&
            $bounds_width == 32 && $bounds_height == 32) {

            #full intersection

            $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0], $src->[1], 32, 32],
                [$map_pos->[0], $map_pos->[1], 32, 32]);

        } elsif ($bounds_x > $ch_pos_x &&
            $bounds_y == $ch_pos_y &&
            $bounds_height == 32) {

            #y axises are equal and character stands lefter the sprite

            #draw remained character's part
            $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1], 32-$bounds_width, 32],
                [$map_pos->[0], $map_pos->[1], 32-$bounds_width, 32]);

            #draw intersection's part
            $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0]+32-$bounds_width, $src->[1], $bounds_width, 32],
                [$map_pos->[0]+32-$bounds_width, $map_pos->[1], $bounds_width, 32]);

        } elsif ($bounds_x < $ch_pos_x+32 &&
            $bounds_y == $ch_pos_y &&
            $bounds_height == 32) {

            #y axises are equal and character stands righter the sprite

            #draw remained character's part
            $display_surface_ref->blit_by($self->sprites,
                [$src->[0]+$bounds_width, $src->[1], 32-$bounds_width,  32],
                [$map_pos->[0]+$bounds_width, $map_pos->[1], 32-$bounds_width, 32]);

            #draw intersection's part
            $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0], $src->[1], $bounds_width, 32],
                [$map_pos->[0], $map_pos->[1], $bounds_width, 32]);

        } elsif ($bounds_y > $ch_pos_y &&
            $bounds_x == $ch_pos_x &&
            $bounds_width == 32) {

            #x axises are equal and character stands upper the sprite

            #draw remained character's part
            $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1], 32, 32-$bounds_height],
                [$map_pos->[0], $map_pos->[1], 32, 32-$bounds_height]);

            #draw intersection's part
            $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0], $src->[1]+32-$bounds_height, 32, $bounds_height],
                [$map_pos->[0], $map_pos->[1]+32-$bounds_height, 32, $bounds_height]);

        } elsif ($bounds_y < $ch_pos_y + 32 &&
            $bounds_x == $ch_pos_x &&
            $bounds_width == 32) {

            #x axises are equal and character stands lower the sprite

            #draw remained character's part
            $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1]+$bounds_height, 32, 32-$bounds_height],
                [$map_pos->[0], $map_pos->[1]+$bounds_height, 32, 32-$bounds_height]);

            #draw intersection's part
            $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0], $src->[1], 32, $bounds_height],
                [$map_pos->[0], $map_pos->[1], 32, $bounds_height]);

        } else {
            #x and y axises are different

            if ($ch_pos_x == $bounds_x &&
                $ch_pos_y == $bounds_y) {

                #draw intersection's part
                $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0], $src->[1], $bounds_width, $bounds_height],
                    [$map_pos->[0], $map_pos->[1], $bounds_width, $bounds_height]);

                #draw remained character's part #1 below the intersection
                $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1]+$bounds_height, $bounds_width, 32-$bounds_height],
                    [$map_pos->[0], $map_pos->[1]+$bounds_height, $bounds_width, 32-$bounds_height]);

                #draw remained character's part #2 righter the intersection
                $display_surface_ref->blit_by($self->sprites, [$src->[0]+$bounds_width, $src->[1], 32-$bounds_width, 32],
                    [$map_pos->[0]+$bounds_width, $map_pos->[1], 32-$bounds_width, 32]);

            } elsif ($ch_pos_x < $bounds_x &&
                $ch_pos_y == $bounds_y) {

                #draw intersection's part
                $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0]+32-$bounds_width, $src->[1], $bounds_width, $bounds_height],
                    [$map_pos->[0]+32-$bounds_width, $map_pos->[1], $bounds_width, $bounds_height]);

                #draw remained character's part #1 lower the intersection
                $display_surface_ref->blit_by($self->sprites, [$src->[0]+32-$bounds_width, $src->[1]+$bounds_height, $bounds_width, 32-$bounds_height],
                    [$map_pos->[0]+32-$bounds_width, $map_pos->[1]+$bounds_height, $bounds_width, 32-$bounds_height]);

                #draw remained character's part #2 lefter the intersection
                $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1], 32-$bounds_width, 32],
                    [$map_pos->[0], $map_pos->[1], 32-$bounds_width, 32]);

            } elsif ($ch_pos_x < $bounds_x &&
                $ch_pos_y < $bounds_y) {

                #draw intersection's part
                $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0]+32-$bounds_width, $src->[1]+32-$bounds_height, $bounds_width, $bounds_height],
                    [$map_pos->[0]+32-$bounds_width, $map_pos->[1]+32-$bounds_height, $bounds_width, $bounds_height]);

                #draw remained character's part #1 upper the intersection
                $display_surface_ref->blit_by($self->sprites, [$src->[0]+32-$bounds_width, $src->[1], $bounds_width, 32-$bounds_height],
                    [$map_pos->[0]+32-$bounds_width, $map_pos->[1], $bounds_width, 32-$bounds_height]);

                #draw remained character's part #2 lefter the intersection
                $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1], 32-$bounds_width, 32],
                    [$map_pos->[0], $map_pos->[1], 32-$bounds_width, 32]);

           } else {
               #condition: $ch_pos_x == $bounds_x && $ch_pos_y < $bounds_y

               #draw intersection's part
               $display_surface_ref->blit_by($self->sprites_overlap, [$src->[0], $src->[1]+32-$bounds_height, $bounds_width, $bounds_height],
                   [$map_pos->[0], $map_pos->[1]+32-$bounds_height, $bounds_width, $bounds_height]);

               #draw remained character's part #1 upper the intersection
               $display_surface_ref->blit_by($self->sprites, [$src->[0], $src->[1], $bounds_width, 32-$bounds_height],
                   [$map_pos->[0], $map_pos->[1], $bounds_width, 32-$bounds_height]);

               #draw remained character's part #2 righter the intersection
               $display_surface_ref->blit_by($self->sprites, [$src->[0]+$bounds_width, $src->[1], 32-$bounds_width, 32],
                   [$map_pos->[0]+$bounds_width, $map_pos->[1], 32-$bounds_width, 32]);

           }
        }
    } else {
        $display_surface_ref->blit_by($self->sprites, $src, $self->calc_map_pos($map_offset_x, $map_offset_y));
    }
    #$display_surface_ref->blit_by($self->sprites, $src, $self->calc_map_pos($map_offset_x, $map_offset_y));
}

#override Movable method
sub update_pos {
    my ($self, $new_dt) = @_;
    my ($x, $y) = @{$self->pos}[0..1];

    if ($self->step_x != 0) {
        my $new_x = $x + $self->step_x_speed*$self->step_x;
        if ($new_x >= 0 && $new_x <= $self->map_width-32) {

            if (!($self->jumping && $y % 32 == 0 && $self->is_map_val($x, $y) && $self->is_map_val($x, $y-1) && $self->is_map_val($x+32, $y))) {

                if ($self->step_x == 1) {
                    if (!$self->is_map_val($new_x+32, $y+($self->jumping ? 0 : 32))) {
                        $self->pos->[0] = $x = $new_x;
                    } else {
                        $self->pos->[0] = $x = 32*(int($new_x/32));
                        #change x direction
                        $self->step_x(-1);
                    }
                } else {
                    if (!$self->is_map_val($new_x, $y+($self->jumping ? 0 : 32))) {
                        $self->pos->[0] = $x = $new_x;
                    } else {
                        $self->pos->[0] = $x = 32*(int($new_x/32)+1);
                        #change x direction
                        $self->step_x(1);
                    }
                }
            }

            if (!$self->jumping) {
                if ($self->step_x == 1 && !$self->is_map_val($x+12, $y+64) || $self->step_x == -1 && !$self->is_map_val($x+20, $y+64)) {

                    $self->jumping(1);
                    $self->velocity(0);
                    $self->jump_dt(Time::HiRes::time);
                }
            }
        }
    }

    if ($self->jumping) {

        if (!$self->velocity) {
            # failing

            my $new_y = 5 + $y + 19.62*(($new_dt - $self->jump_dt)**2);
            my ($test_y, $catched_thru_pass) = ($y, 0);

            while ($test_y < $new_y) {

                if ($self->step_x == 0) {
                    if ($self->is_map_val($x, $test_y)) {
                        $self->pos->[0] = $x = (1 + int($x/32)) * 32;
                    } elsif ($self->is_map_val($x+32, $test_y)) {
                        $self->pos->[0] = $x = int($x/32) * 32;
                    }
                }

                if ($self->is_map_val($x+16, $test_y+32)) {
                    $self->pos->[1] = $y = int($test_y - $test_y%32);
                    $self->jumping(0);

                    $catched_thru_pass = 1;
                    last;
                } else {
                    $test_y += 8;
                }
            }

            if (!$catched_thru_pass) {
                $self->pos->[1] = $y = $new_y;
            }
        } else {
            # jumping up

            if ($y % 32 == 0 && $self->is_map_val($x, $y) && $self->is_map_val($x, $y-1) && $self->is_map_val($x+32, $y)) {
                $self->jumping(0);
            } else {

                my $new_velocity = $self->velocity - 3.6*($new_dt - $self->jump_dt);
                $new_velocity = 0 if $new_velocity < 0;

                my $new_y = $y - $new_velocity;
                if (!($self->is_map_val($x, $new_y) || $self->is_map_val($x+31, $new_y))) {
                    $self->pos->[1] = $y = $new_y;
                    $self->velocity($new_velocity);
                } else {
                    $self->velocity(0);
                }
            }
        }
    }
}

#new method
sub is_map_val {
    my $self = shift;
    return exists $self->map_ref->{int($_[0]/32) + int(($self->map_height-$_[1])/32)*($self->map_width/32)};
}

#override Movable method
sub update_index {
    my ($self, $new_dt) = @_;
    if ($new_dt - $self->sprite_dt >= 0.1) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == 3) {
            $self->{sprite_index} = 0;
        }
    }
}

#override
sub _build_sprites {
    return TextureManager->instance->get('BAD_GUY');
}

#new method
sub _build_sprites_overlap {
    my $result = TextureManager->instance->get('BAD_GUY_OVERLAP');
    SDL::Video::set_alpha($result, SDL_RLEACCEL | SDL_SRCALPHA, 96);
    return $result;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
