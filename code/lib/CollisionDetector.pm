package CollisionDetector;

use strict;
use warnings;
use 5.010;

use Mouse;
use POSIX qw/ceil/;
use List::Util qw/max min/;
use Loop::Constants;

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
    my ($self, $x, $y) = @_;
    state $blocks_per_vrow = int($self->level_data->h/$SPRITE_H);
    state $blocks_per_hrow = $self->level_data->w/$SPRITE_W;

    return exists $self->level_data->blocks->{int($x/$SPRITE_W) +
                                              ($blocks_per_vrow-int($y/$SPRITE_H)-1)*$blocks_per_hrow};
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
