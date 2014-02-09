package Character;

use strict;
use warnings;
use 5.010;

use Mouse;
use Time::HiRes;
use TextureManager;
use SDL::Video;
use Camera;
use AnimatedSprite;
use Loop::Constants;
use Inline with => 'SDL';

extends 'AnimatedSprite';

has look_sprites => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Int]]',
    default => sub {
        [
            [0, $SPRITE_W*2, $SPRITE_W, $SPRITE_H], #LOOK_AT_RIGHT
            [0, $SPRITE_W,   $SPRITE_W, $SPRITE_H], #LOOK_AT_LEFT
            [$SPRITE_W, 0, $SPRITE_W, $SPRITE_H] #IDLE
        ]
    }
);

has move_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time
);

has step_x => (
    is => 'rw',
    isa => 'Int',
    default => 0 #IDLE
);

has vx => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has vy => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has max_vx => (
    is => 'rw',
    isa => 'Num',
    default => 350
);

has max_vy=> (
    is => 'rw',
    isa => 'Num',
    default => 250
);

has acc_x => (
    is => 'rw',
    isa => 'Num',
    default => 250
);

has 'jumping' => (
    is => 'rw',
    isa => 'Int',
    default => 0
);

#has cur_sprites => (
#    is => 'rw',
#    isa => 'SDL::Surface'
#);

has damage_mode => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has damage_duration => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has cur_damage_counter => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has show_damage => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has sprites_inverted => (
    is => 'ro',
    isa => 'SDL::Surface',
    lazy => 1,
    builder => '_build_sprites_inverted',
    init_arg => undef
);

has move_key_hold => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has key_hold_start_time => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has 'riding_block' => (
    is => 'rw',
    isa => 'Maybe[RidingBlock]',
    default => undef
);

sub draw {
    my ($self, $display_surface, $map_x, $map_y) = @_;

    if ($self->damage_mode) {
        if (++$self->{cur_damage_counter} == 5) {
            $self->show_damage($self->show_damage == 1 ? 0 : 1);
            $self->cur_damage_counter(0);
        }

        $display_surface->blit_by(
            $self->show_damage ? $self->sprites_inverted : $self->img,
            $self->cur_render_rect,
            [$map_x-$self->half_w, $map_y-$self->half_h, $self->w, $self->h]);

        $self->damage_mode(0) unless --$self->{damage_duration};
    } else {
        $display_surface->blit_by(
            $self->img,
            $self->cur_render_rect,
            [$map_x-$self->half_w, $map_y-$self->half_h, $self->w, $self->h]);
    }
}

sub handle_collision {
    my ($self) = @_;

    if (!$self->damage_mode) {
        $self->damage_mode(1);
        $self->damage_duration(20);
        $self->cur_damage_counter(0);
        $self->show_damage(1);
    }

    handle_collision_c($self->img, $self->look_sprites);

    ####HERE BELOW IS A PERL REWRITE
    ####
    ####
    ####
    ####

    #my $img = $self->img;

    #if (SDL::Video::MUSTLOCK($img)) {
    #    SDL::Video::lock_surface($img);
    #}

    #my $width = $img->pitch/4;

    #my $R_mask = $img->format->Rmask;
    ##my $G_mask = $img->format->Gmask;
    ##my $B_mask = $img->format->Bmask;

    #foreach my $look_sprites (@{$self->look_sprites}) {
    #    my $base = $look_sprites->[1]*$width;

    #    my $cur = $base;
    #    my $val;
    #    my $index = $cur;

    #    foreach my $y (0..$SPRITE_H) {
    #        foreach my $x (0..$SPRITE_W*3) {
    #            $val = $img->get_pixel(++$index);
    #            if ($val != 0xFFFFFF) {
    #                my $r = $val & $R_mask;
    #                #my $g = ($val & $G_mask);
    #                #my $b = ($val & $B_mask);
    #                if ($r < $R_mask) {
    #                    $img->set_pixels($index, ($r+0x10000)+($val-$r));
    #                }
    #            }
    #        }
    #        $index = ($cur += $width);
    #    }
    #}

    #if (SDL::Video::MUSTLOCK($img)) {
    #    SDL::Video::unlock_surface($img);
    #}

    ####
    ####
    ####
    ####
    ####
}

sub update_pos {
    my ($self, $new_dt) = @_;

    my $dt_diff = $new_dt - $self->move_dt;

    #if we are moving horizontally
    if ($self->move_key_hold) {
        if ($self->vx < 0 && $self->step_x == 1) {
            $self->{vx} += abs($self->vx*0.4);
        }
        if ($self->vx > 0 && $self->step_x == -1) {
            $self->{vx} -= $self->vx*0.4;
        }
        my $acc_x = $self->acc_x*$dt_diff;
        $self->{vx} += $self->step_x*$acc_x;
    } else {
        my $acc_x = $self->acc_x*$dt_diff*5;
        if ($self->vx > 0) {
            $self->{vx} -= $acc_x;
            $self->vx(0) if $self->vx < 0;
        } elsif ($self->vx < 0) {
            $self->{vx} += $acc_x;
            $self->vx(0) if $self->vx > 0;
        }
    }

    $self->vx($self->max_vx) if $self->vx > $self->max_vx;
    $self->vx(-$self->max_vx) if $self->vx < -$self->max_vx;

    my $new_pos_x = $self->x + $self->vx*$dt_diff;
    my $new_pos_y = $self->y;

    if ($self->jumping) {
        $new_pos_y -= $self->vy*$dt_diff;
    }

    if ($self->riding_block) {
        if ($self->riding_block->is_horizontal_move) {
            $new_pos_x += $self->riding_block->step_speed*$dt_diff*($self->riding_block->moving_type == $MOVEMENT->{LEFT} ? -1 : 1);
        } else {
            $new_pos_y += $self->riding_block->step_speed*$dt_diff*($self->riding_block->moving_type == $MOVEMENT->{UP} ? -1 : 1);
        }
    } else {
        $self->{vy} -= $GRAVITY*$dt_diff;
        $new_pos_y -= $self->vy*$dt_diff;
    }

    #positions to be checked
    $self->newx($new_pos_x);
    $self->newy($new_pos_y);

    #update the move_dt
    $self->move_dt($new_dt);
}

sub update_index {
    my ($self, $new_dt) = @_;

    if ($new_dt - $self->sprite_dt >= $self->speed_change_dt) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == $self->sprites_count) {
            $self->{sprite_index} = 0;
        }

        if ($self->step_x) {
            $self->render_rect($self->look_sprites->[$self->step_x == 1 ? $LOOK_AT_RIGHT : $LOOK_AT_LEFT]);
            $self->{cur_render_rect} = [@{$self->render_rect}];
            $self->cur_render_rect->[0] += $SPRITE_W*$self->sprite_index;
        } else {
            $self->render_rect($self->look_sprites->[$LOOK_AT_ME]);
            $self->{cur_render_rect} = [@{$self->render_rect}];
            $self->cur_render_rect->[0] = $SPRITE_W;
        }
    }
}

sub _build_img {
    TextureManager->instance->get('MAIN_CHARACTER');
}

sub _build_sprites_inverted {
    TextureManager->instance->get('MAIN_CHARACTER_INVERTED');
}

use Inline C => <<'END';
void handle_collision_c(SDL_Surface *img, SV *sv_look_sprites) {

    const int R_mask = img->format->Rmask;
    const int width = img->w;

    AV *av_look_sprites = (AV *) SvRV(sv_look_sprites);
    const int look_sprites_count = av_top_index(av_look_sprites);
    
    if (look_sprites_count >= 0) {

        if (SDL_MUSTLOCK(img)) {
            SDL_LockSurface(img);
        }

        unsigned int *pixels = img->pixels;

        int i;
        for (i = 0; i <= look_sprites_count; ++i) {
            SV **sv_look_sprite = av_fetch(av_look_sprites, i, 0);
            AV *av_sprites = (AV *) SvRV(*sv_look_sprite);

            SV **value = av_fetch(av_sprites, 1, 0);
            const int base = SvIV(*value)*width;

            //show must go on!
            int cur = base;
            int val;
            int index = cur;

            int y, x;
            for (y = 0; y <= 32; ++y) {
                for (x = 0; x <= 32*3; ++x) {
                    ++index;
                    val = *(pixels + index);
                    if (val != 0xFFFFFF) {
                        const int r = val & R_mask;
                        if (r < R_mask) {
                            pixels[index] = (r+0x10000)+(val-r);
                        }
                    }
                }

                index = (cur += width);
            }
        }

        if (SDL_MUSTLOCK(img)) {
            SDL_UnlockSurface(img);
        }
    }
}
END

sub BUILD {
    my ($self) = @_;

    $self->speed_change_dt(0.1);
    $self->sprites_count(3); #3 per animation
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
