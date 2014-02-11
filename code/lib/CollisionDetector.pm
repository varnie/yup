package CollisionDetector;

use strict;
use warnings;
use 5.010;

use Mouse;
use POSIX qw/ceil/;
use List::Util qw/max min/;
use Loop::Constants;
use Inline with => 'SDL';

has level_data => (
    is => 'ro',
    isa => 'LevelData',
    required => 1
);

has 'candidates' => (
    is => 'ro',
    isa => 'ArrayRef[Sprite]',
    lazy => 1,
    builder => '_build_candidates'
);

has 'particles_chunk_candidates' => (
    is => 'ro',
    isa => 'ArrayRef[ParticlesChunkBase]',
    lazy => 1,
    default => sub { [] }
);

use Inline C => <<'END';
void particles_resolve(SV *self) {

    const HV *obj_hash = SvRV(self);
    const AV *av_particles_chunk_candidates = (AV *) SvRV(*hv_fetch(obj_hash, "particles_chunk_candidates", 26, 0)); //26 is strlen("particles_chunk_candidates")
    const int particles_chunk_count = av_top_index(av_particles_chunk_candidates);

    if (particles_chunk_count >= 0) {

        const int points[8][2] = {
            {0, 0}, {4, 0}, //top
            {0, 4}, {4, 4}, //bottom
            {0, 0}, {0, 4}, //left
            {4, 0}, {4, 4}  //right
        };

        int i;
        for (i = 0; i <= particles_chunk_count; ++i) {
            SV *sv_particles_chunk = *av_fetch(av_particles_chunk_candidates, i, 0);
            HV *particles_obj_hash = SvRV(sv_particles_chunk);

            AV *av_particles = (AV *) SvRV(*hv_fetch(particles_obj_hash, "items", 5, 0)); //5 is strlen("items")
            const int particles_count = av_top_index(av_particles);

            if (particles_count >= 0) {

                int j;
                for (j = 0; j <= particles_count; ++j) {

                    HV *particle_obj_hash = SvRV(*av_fetch(av_particles, j, 0));

                    if (SvIV(*hv_fetch(particle_obj_hash, "ttl", 3, 0)) > 0) { //3 is strlen("ttl")
                        //alive

                        SV *sv_x = *hv_fetch(particle_obj_hash, "x", 1, 0);
                        SV *sv_y = *hv_fetch(particle_obj_hash, "y", 1, 0);
                        int x = SvIV(sv_x);
                        int y = SvIV(sv_y);

                        //int x = SvIV(*hv_fetch(particle_obj_hash, "x", 1, 0)); //1 is strlen("x")
                        //int y = SvIV(*hv_fetch(particle_obj_hash, "y", 1, 0)); //1 is strlen("y")

                        int default_updx = SvIV(*hv_fetch(particle_obj_hash, "newx", 4, 0)); //4 is strlen("newx")
                        int default_updy = SvIV(*hv_fetch(particle_obj_hash, "newy", 4, 0)); //4 is strlen("newy")

                        int upd_newx = default_updx;
                        int upd_newy = default_updy;

                        int left_x = x < upd_newx ? x : upd_newx;
                        int right_x = x+4 > upd_newx+4 ? x+4 : upd_newx+4;
                        int top_y = y < upd_newy ? y : upd_newy;
                        int bottom_y = y+4 > upd_newy+4 ? y+4 : upd_newy+4;

                        //printf("left_x was: %d right_x was: %d\n", left_x, right_x);

                        left_x = 32*((int)(left_x/32));
                        right_x = 32*((int)(right_x/32)) + (right_x%32 > 0 ? 32 : 0);
                        top_y = 32*(ceil((int)top_y/32))-32;
                        bottom_y = 32*ceil(bottom_y/32);

                        int move_right = x < upd_newx;
                        int move_left = x > upd_newx;
                        int move_up = upd_newy < y;
                        int move_down = upd_newy > y;

                        //printf("top:%d bottom:%d left:%d right:%d\n", top_y, bottom_y, left_x, right_x);

                        int xx, yy;
                        for (xx = left_x; xx <= right_x; xx += 32) {
                            for (yy = top_y; yy <= bottom_y; yy += 32) {
                                if (is_map_val_c(self, xx, yy)) {

                                    int iter = 0;
                                    int hit_top = 1;
                                    int hit_bottom = 1;
                                    int hit_x = 1;

                                    while (iter < 3 && (hit_top || hit_bottom || hit_x)) {

                                        hit_top = hit_bottom = hit_x = 0;

                                        //dir: 0=top, 1=bottom, 2=left, 3=right
                                        int dir;
                                        for (dir = 0; dir <= 3; ++dir) {

                                            if (dir == 0 && move_down ||
                                                dir == 1 && move_up ||
                                                dir == 2 && move_right ||
                                                dir == 3 && move_left)
                                            {
                                                continue;
                                            }

                                            int projected_y = dir <= 1 ? upd_newy - y : 0;
                                            int projected_x = dir >= 2 ? upd_newx - x : 0;

                                            int index = 2 * dir;

                                            while (is_point_within_c(x + projected_x + points[index][0],   y + projected_y + points[index][1], xx, yy) &&
                                                   is_point_within_c(x + projected_x + points[index+1][0], y + projected_y + points[index+1][1], xx, yy))
                                            {
                                                if (dir == 0) {
                                                    ++projected_y;
                                                    ++upd_newy;
                                                } else if (dir == 1) {
                                                    --projected_y;
                                                    --upd_newy;
                                                } else if (dir == 2) {
                                                    ++projected_x;
                                                    ++upd_newx;
                                                } else if (dir == 3) {
                                                    --projected_x;
                                                    --upd_newx;
                                                }
                                            }

                                            if (upd_newy > default_updy) {
                                                hit_top = 1;
                                            } else if (upd_newy < default_updy) {
                                                hit_bottom = 1;
                                            }

                                            if (upd_newx != default_updx) {
                                                hit_x = 1;
                                            }
                                        }

                                        ++iter;
                                    }
                                }
                            }
                        }


                        if (upd_newy > default_updy) {
                            //first possible way
                            //hv_store(particle_obj_hash, "vel_y", 5, newSViv(abs( SvIV(*hv_fetch(particle_obj_hash, "vel_y", 5, 0)))), 0);

                            //second possible way
                            SV *foo = *hv_fetch(particle_obj_hash, "vel_y", 5, 0);
                            double val = SvNV(foo);
                            val = abs(val);
                            SvNV_set(foo, val);
                        } else if (upd_newy < default_updy) {
                            //hv_store(particle_obj_hash, "vel_y", 5, newSViv(- abs( SvIV(*hv_fetch(particle_obj_hash, "vel_y", 5, 0)))), 0);

                            SV *foo = *hv_fetch(particle_obj_hash, "vel_y", 5, 0);
                            double val = SvNV(foo);
                            val = - abs(val);
                            SvNV_set(foo, val);
                        }

                        if (upd_newx != default_updx) {
                            //hv_store(particle_obj_hash, "vel_x", 5, newSViv(-1 * SvIV(*hv_fetch(particle_obj_hash, "vel_x", 5, 0))), 0);
                            hv_store(particle_obj_hash, "ttl", 3, newSViv(-1), 0); //3 is strlen("ttl") //just a hack  to kill the particle
                        }

                        SvIV_set(sv_x, upd_newx);
                        SvIV_set(sv_y, upd_newy);
                    }
                }
            }
        }
    }
}

int is_map_val_c(SV *self, int x, int y) {

    const HV *obj_hash = SvRV(self);
    const HV *level_data_hash = SvRV(*hv_fetch(obj_hash, "level_data", 10, 0)); //10 is strlen("level_data")

    const int blocks_per_vrow = (int) (SvIV(*hv_fetch(level_data_hash, "h", 1, 0)) / 32); //1 is strlen("h")
    const int blocks_per_hrow = SvIV(*hv_fetch(level_data_hash, "w", 1, 0)) / 32; //1 is strlen("w")

    const HV *level_data_blocks = SvRV(*hv_fetch(level_data_hash, "blocks", 6, 0)); //6 is strlen("blocks")

    SV *key_sv = newSViv((int)(x/32) + (blocks_per_vrow - (int)(y/32) - 1) * blocks_per_hrow);
    return hv_exists_ent(level_data_blocks, key_sv, 0);
}

int is_point_within_c(int x, int y, int obj_x, int obj_y) {
    return x >= obj_x && x <= obj_x+32 &&
           y >= obj_y && y <= obj_y+32;
}
END

#sub particles_resolve {
#    my ($self) = @_;
#
#    &particles_resolve_c($self);
#    return;
#    my @points = (
#        [0, 0], [8, 0], #top
#        [0, 8], [8, 8], #bottom
#        [0, 0], [0, 8], #left
#        [8,  0], [8, 8] #right
#    );
#
#    foreach my $particles_chunk (@{$self->particles_chunk_candidates}) {
#
#        foreach my $p (@{$particles_chunk->items}) {
#
#            if ($p->ttl <= 0) {
#                next;
#            }
#
#            my ($default_updx, $default_updy) = ($p->newx, $p->newy);
#            my ($upd_newx, $upd_newy) = ($default_updx, $default_updy);
#
#            my $left_x = min($p->x, $upd_newx);
#            my $right_x  = max($p->x+8, $upd_newx+8);
#            my $top_y =  min($p->y, $upd_newy);
#            my $bottom_y = max($p->y+8, $upd_newy+8);
#
#            $left_x = $SPRITE_W*int($left_x/$SPRITE_W);
#            $right_x = $SPRITE_W*ceil(int($right_x)/$SPRITE_W);
#            $top_y = $SPRITE_H*(ceil(int($top_y)/$SPRITE_H))-$SPRITE_H;
#            $bottom_y = $SPRITE_H*ceil($bottom_y/$SPRITE_H);
#
#            my @objs;
#            for (my $x = $left_x; $x <= $right_x; $x += $SPRITE_W) {
#                for (my $y = $top_y; $y <= $bottom_y; $y += $SPRITE_H) {
#                    if ($self->is_map_val($x, $y)) {
#                        push @objs, [$x+$SPRITE_HALF_W, $y+$SPRITE_HALF_H]; #center of the object
#                    }
#                }
#            }
#
#            if (@objs) {
#                my $move_right = $p->x < $upd_newx;
#                my $move_left = $p->x > $upd_newx;
#                my $move_up = $upd_newy < $p->y;
#                my $move_down = $upd_newy > $p->y;
#
#                foreach my $obj (@objs) {
#                    my $iter = 0;
#
#                    my ($hit_top, $hit_bottom, $hit_x) = (1, 1, 1);
#                    while ($iter < 1 && ($hit_top || $hit_bottom || $hit_x)) {
#
#                        $hit_top = $hit_bottom = $hit_x = 0;
#
#                        #dir: 0=top, 1=bottom, 2=left, 3=right;
#                        foreach my $dir (0..3) {
#                            next if ($dir == 0 && $move_down) ||
#                                ($dir == 1 && $move_up) ||
#                                ($dir == 2 && $move_right) ||
#                                ($dir == 3 && $move_left);
#
#                            my $projected_y = $dir <= 1 ? $upd_newy-$p->y : 0;
#                            my $projected_x = $dir >= 2 ? $upd_newx-$p->x : 0;
#
#                            my $index = 2*$dir;
#
#                            while ($self->is_point_within($p->x + $projected_x + ${$points[$index]}[0], $p->y + $projected_y + ${$points[$index]}[1], $obj)
#                                || $self->is_point_within($p->x + $projected_x + ${$points[$index+1]}[0], $p->y + $projected_y + ${$points[$index+1]}[1], $obj)) {
#                                if ($dir == 0) {
#                                    ++$projected_y;
#                                    ++$upd_newy;
#                                } elsif ($dir == 1) {
#                                    --$projected_y;
#                                    --$upd_newy;
#                                } elsif ($dir == 2) {
#                                    ++$projected_x;
#                                    ++$upd_newx;
#                                } elsif ($dir == 3) {
#                                    --$projected_x;
#                                    --$upd_newx;
#                                }
#                            }
#
#                            if ($upd_newy > $default_updy) {
#                                $hit_top = 1;
#                                $p->vy(0);
#                            } elsif ($upd_newy < $default_updy) {
#                                $hit_bottom = 1;
#                                $p->vy(0);
#                            }
#
#                            if ($upd_newx != $default_updx) {
#                                $hit_x = 1;
#                                #$p->vx(0);
#                            }
#                        }
#
#                        ++$iter;
#                    }
#                }
#            }
#
#            $p->x($upd_newx);
#            $p->y($upd_newy);
#        }
#    }
#};

sub resolve {
    my ($self) = @_;

    foreach my $c (@{$self->candidates}) {

        my ($default_updx, $default_updy) = ($c->newx, $c->newy);
        my ($upd_newx, $upd_newy) = ($default_updx, $default_updy);

        my $left_x = min($c->x-$c->half_w+4, $upd_newx-$c->half_w+4);
        my $right_x  = max($c->x+$c->half_w-4, $upd_newx+$c->half_w-4);
        my $top_y =  min($c->y-$c->half_h, $upd_newy-$c->half_h);
        my $bottom_y = max($c->y+$c->half_h, $upd_newy+$c->half_h);

        $left_x = $SPRITE_W*int($left_x/$SPRITE_W);
        $right_x = $SPRITE_W*ceil(int($right_x)/$SPRITE_W);
        $top_y = $SPRITE_H*(ceil(int($top_y)/$SPRITE_H))-$SPRITE_H;
        $bottom_y = $SPRITE_H*ceil($bottom_y/$SPRITE_H);

        my @objs;
        for (my $x = $left_x; $x <= $right_x; $x += $SPRITE_W) {
            for (my $y = $top_y; $y <= $bottom_y; $y += $SPRITE_H) {
                if ($self->is_map_val($x, $y)) {
                    push @objs, [$x+$SPRITE_HALF_W, $y+$SPRITE_HALF_H]; #center of the object
                }
                my $obj;
                if (($obj = $self->is_riding_block_val($x, $y))) {
                    push @objs, $obj;
                }
            }
        }

        if (@objs) {

            my @points = (
                [-8, -15], [8, -15], #top
                [-8,  15], [8,  15], #bottom
                [-12, -14], [-12, 14], #left
                [12,  -14], [12,  14] #right
            );

            my $move_right = $c->x < $upd_newx;
            my $move_left = $c->x > $upd_newx;
            my $move_up = $upd_newy < $c->y;
            my $move_down = $upd_newy > $c->y;

            foreach my $obj (@objs) {
                my $iter = 0;

                my ($hit_top, $hit_bottom, $hit_x) = (1, 1, 1);
                while ($iter < 3 && ($hit_top || $hit_bottom || $hit_x)) {

                    $hit_top = $hit_bottom = $hit_x = 0;

                    #dir: 0=top, 1=bottom, 2=left, 3=right;
                    foreach my $dir (0..3) {
                        if (!blessed($obj)) {
                            next if ($dir == 0 && $move_down) ||
                            ($dir == 1 && $move_up) ||
                            ($dir == 2 && $move_right) ||
                            ($dir == 3 && $move_left);
                        }

                        my $projected_y = $dir <= 1 ? $upd_newy-$c->y : 0;
                        my $projected_x = $dir >= 2 ? $upd_newx-$c->x : 0;

                        my $index = 2*$dir;

                        if (blessed($obj)) {
                            while ($self->is_point_within_block($c->x + $projected_x + ${$points[$index]}[0], $c->y + $projected_y + ${$points[$index]}[1], $obj)
                                || $self->is_point_within_block($c->x + $projected_x + ${$points[$index+1]}[0], $c->y + $projected_y + ${$points[$index+1]}[1], $obj)) {
                                if ($dir == 0) {
                                    $projected_y += 8;
                                    $upd_newy += 8;
                                    last;
                                } elsif ($dir == 1) {
                                    --$projected_y;
                                    --$upd_newy;
                                } elsif ($dir == 2) {
                                    ++$projected_x;
                                    ++$upd_newx;
                                } elsif ($dir == 3) {
                                    --$projected_x;
                                    --$upd_newx;
                                }
                            }
                        } else {
                            while ($self->is_point_within($c->x + $projected_x + ${$points[$index]}[0], $c->y + $projected_y + ${$points[$index]}[1], $obj)
                                || $self->is_point_within($c->x + $projected_x + ${$points[$index+1]}[0], $c->y + $projected_y + ${$points[$index+1]}[1], $obj)) {
                                if ($dir == 0) {
                                    ++$projected_y;
                                    ++$upd_newy;
                                } elsif ($dir == 1) {
                                    --$projected_y;
                                    --$upd_newy;
                                } elsif ($dir == 2) {
                                    ++$projected_x;
                                    ++$upd_newx;
                                } elsif ($dir == 3) {
                                    --$projected_x;
                                    --$upd_newx;
                                }
                            }
                        }

                        if ($upd_newy > $default_updy) {
                            $hit_top = 1;
                            $c->vy(0);
                        } elsif ($upd_newy < $default_updy) {
                            $hit_bottom = 1;
                            $c->vy(0);
                        }

                        if ($upd_newx != $default_updx) {
                            $hit_x = 1;
                            $c->vx(0);
                        }
                    }

                    ++$iter;
                }
            }
        }

        my $is_on_riding_block = $self->is_riding_block_val($upd_newx-12, $upd_newy-$SPRITE_HALF_H+1);
        $c->riding_block($is_on_riding_block);
        $c->jumping(int(!($is_on_riding_block || $self->is_map_val($upd_newx-12, $upd_newy+$SPRITE_H) || $self->is_map_val($upd_newx+12, $upd_newy+$SPRITE_H))));

        $c->x($upd_newx);
        $c->y($upd_newy);
    }
};

sub is_point_within {
    my ($self, $x, $y, $obj) = @_;
    my ($obj_x, $obj_y) = ($obj->[0], $obj->[1]);

    return $x >= $obj_x-$SPRITE_HALF_W && $x <= $obj_x+$SPRITE_HALF_W &&
           $y >= $obj_y-$SPRITE_HALF_H && $y <= $obj_y+$SPRITE_HALF_H;
};

sub is_point_within_block {
    my ($self, $x, $y, $obj) = @_;

    return $x >= $obj->x-$obj->half_w && $x <= $obj->x+$obj->half_w &&
           $y >= $obj->y-$obj->half_h && $y <= $obj->y+$obj->half_h;
}

sub is_map_val {
    my ($self) = shift;
    state $blocks_per_vrow = int($self->level_data->h/$SPRITE_H);
    state $blocks_per_hrow = $self->level_data->w/$SPRITE_W;

    return exists $self->level_data->blocks->{int($_[0]/$SPRITE_W) +
                                              ($blocks_per_vrow-int($_[1]/$SPRITE_H)-1)*$blocks_per_hrow};
}

sub is_riding_block_val {
    my ($self, $x, $y) = @_;

    foreach my $riding_block (@{$self->level_data->riding_blocks}) {
        my ($riding_block_x, $riding_block_y) = ($riding_block->x, $riding_block->y);

        if (!($x+24 <= $riding_block_x-$riding_block->half_w
              || $riding_block_x+$riding_block->half_w <= $x
              || $y+$SPRITE_H <= $riding_block_y-$riding_block->half_h
              || $riding_block_y+$riding_block->half_h <= $y)) {

            return $riding_block;
        }
    }

    return undef;
}

sub is_bad_guy_val {
    my ($self, $x, $y) = @_;

    foreach my $bad_guy (@{$self->level_data->bad_guys}) {
        my ($bad_guy_x, $bad_guy_y) = ($bad_guy->x, $bad_guy->y);
        if (!($x+24 < $bad_guy_x-$bad_guy->half_w
              || $bad_guy_x+$bad_guy->half_w < $x
              || $y+$SPRITE_H < $bad_guy_y-$bad_guy->half_h
              || $bad_guy_y+$bad_guy->half_h < $y)) {

            return $bad_guy;
        }
    }

    return undef;
}


sub _build_candidates {
    my ($self) = @_;

    my @result;
    push @result, $self->level_data->ch;

    return \@result;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
