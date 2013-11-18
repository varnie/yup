package Character;

use strict;
use warnings;
use 5.010;

use Time::HiRes;

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

#new attribute
has move_key_hold => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

#new attribute
has key_hold_start_time => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

#new attribute
has slide => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

#new attribute
has aux => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

#new method
sub reset_velocity {
    shift->velocity(6);
}

#override Entity method
sub calc_map_pos {
    my ($self) = @_;
    my ($pos_x, $pos_y) = @{$self->pos}[0..1];
    my $x = (($pos_x < $self->screen_w/2) || ($self->screen_w >= $self->map_width)) ? $pos_x : $pos_x - $self->screen_w/2 > $self->map_width - $self->screen_w ? $pos_x - ($self->map_width - $self->screen_w) : $self->screen_w/2;

    my $y = (($pos_y < $self->screen_h/2) || ($self->screen_h >= $self->map_height)) ? $pos_y : $pos_y - $self->screen_h/2 > $self->map_height - $self->screen_h ? $pos_y - ($self->map_height - $self->screen_h) : $self->screen_h/2;

    @{$self->map_pos}[0..1] = ($x, $y);
    return $self->map_pos;
}

#override
sub draw {
    my ($self, $display_surface_ref) = @_;
    my $src = do {
        if ($self->step_x) {
            my $pattern = $self->look_sprites->[$self->step_x == 1 ? LOOK_AT_RIGHT : LOOK_AT_LEFT];
            $pattern->[0] = 32*$self->sprite_index;
            $pattern;
        } elsif (!$self->slide) {
            $self->look_sprites->[LOOK_AT_ME];
        } else {
            $self->look_sprites->[$self->slide == 1 ? LOOK_AT_RIGHT : LOOK_AT_LEFT];
        }
    };

    my $bounds = CollisionDetector->instance->strict_intersect_bounds($self->pos);
    if ($bounds) {
        my ($bounds_x, $bounds_y, $bounds_width, $bounds_height) = @{$bounds};

        my $map_pos = $self->calc_map_pos;
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
        $display_surface_ref->blit_by($self->sprites, $src, $self->calc_map_pos);
    }
}

#new method
sub handle_collision {
    my ($self) = @_;
    my $sprites = $self->sprites;

    if (SDL::Video::MUSTLOCK($sprites)) {
        SDL::Video::lock_surface($sprites);
    }

    my $width = $sprites->pitch/4;

    my $R_mask = $sprites->format->Rmask;
    #my $G_mask = $sprites->format->Gmask;
    #my $B_mask = $sprites->format->Bmask;

    foreach my $look_sprites (@{$self->look_sprites}) {
        my $base = $look_sprites->[1]*$width;
        my $cur = $base;
        foreach my $y (0..32) {
            my $index = ($cur += $width);
            foreach my $x (0..32*3) {
                my $val = $sprites->get_pixel(++$index);

                if ($val != 0xFFFFFF) {

                    my $r = $val & $R_mask;
                    #my $g = ($val & $G_mask);
                    #my $b = ($val & $B_mask);

                    $sprites->set_pixels($index, ($r < $R_mask ? ($r+0x10000) : $r)+($val-$r));
                }
            }
        }
    }

    if (SDL::Video::MUSTLOCK($sprites)) {
        SDL::Video::unlock_surface($sprites);
    }
}

#override Movable method
sub update_pos {
    my ($self, $new_dt) = @_;
    my ($x, $y) = @{$self->pos}[0..1];

    if ($self->step_x || $self->slide) {
        my $new_x = $x;

        if ($self->step_x) {
            my $add_x = $self->move_key_hold ? ($new_dt - $self->key_hold_start_time)*4 : 0;
            $add_x = 4 if $add_x > 4;
            $self->aux($add_x);
            $new_x += ($self->step_x_speed + $add_x)*$self->step_x;
        } else {
            my $new_aux = $self->aux - ($new_dt - $self->key_hold_start_time);
            if ($new_aux < 0) {
                $new_aux = 0;
            } else {
                $new_x += $self->slide*$new_aux;
            }

            $self->aux($new_aux);
        }

        if ($new_x != $x && $new_x >= 0 && $new_x <= $self->map_width-32) {

            if (!($self->jumping && $y % 32 == 0 && $self->is_map_val($x, $y) && $self->is_map_val($x, $y-1) && $self->is_map_val($x+32, $y))) {

                if ($self->step_x == 1 || $self->slide == 1) {
                    if (!$self->is_map_val($new_x+32, $y+($self->jumping ? 0 : 32))) {
                        $self->pos->[0] = $x = $new_x;
                    } else {
                        $self->pos->[0] = $x = 32*(int($new_x/32));
                    }
                } elsif ($self->step_x == -1 || $self->slide == -1) {
                    if (!$self->is_map_val($new_x, $y+($self->jumping ? 0 : 32))) {
                        $self->pos->[0] = $x = $new_x;
                    } else {
                        $self->pos->[0] = $x = 32*(int($new_x/32)+1);
                    }
                }
            }

            if (!$self->jumping) {
                if ((($self->step_x == 1 || $self->slide == 1) && !$self->is_map_val($x+12, $y+64)) ||
                    (($self->step_x == -1 || $self->slide == -1) && !$self->is_map_val($x+20, $y+64))) {

                    $self->jumping(1);
                    $self->velocity(0);
                    $self->jump_dt(Time::HiRes::time);
                }
            }
        }

        $self->slide(0) if !$self->aux;
    }

    if ($self->jumping) {

        if (!$self->velocity) {
            # failing

            my $new_y = 5 + $y + 19.62*(($new_dt - $self->jump_dt)**2);
            my ($test_y, $catched_thru_pass) = ($y, 0);

            while ($test_y < $new_y) {

                if (!$self->step_x && !$self->slide) {
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

                my $new_velocity = $self->velocity - 2.2*($new_dt - $self->jump_dt);
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
    return TextureManager->instance->get('MAIN_CHARACTER');
}

#new method
sub _build_sprites_overlap {
    return TextureManager->instance->get('OVERLAP');
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
