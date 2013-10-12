package Character;

use strict;
use warnings;
use 5.010;

use Mouse;
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use Time::HiRes;

use TextureManager;

use constant {
LOOK_AT_RIGHT => 0,
LOOK_AT_LEFT => 1,
LOOK_AT_ME => 2
};

has look_sprites => (
is => 'rw',
isa => 'ArrayRef[ArrayRef[Num]]',
default => sub {[ [0, 32*2, 32, 32], [0, 32, 32, 32], [32, 0, 32, 32] ]}
);

has map_pos => (
is => 'rw',
isa => 'ArrayRef[Num]',
default => sub{ [0, 0, 32, 32] }
);

has velocity => (
is => 'rw',
isa => 'Num',
default => 6,
required => 1
);

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
default => 0
);

has sprite_dt => (
is => 'rw',
isa => 'Num',
default => Time::HiRes::time,
lazy => 1
);

has step_x => (
is => 'rw',
isa => 'Num',
default => 0
);

has step_x_speed => (
is => 'rw',
isa => 'Num',
default => 2.8
);

has pos => (
is => 'rw',
isa => 'ArrayRef[Num]',
default => sub {[0, 100, 32, 32]}
);

has dt => (
is => 'rw',
isa => 'Num',
default => Time::HiRes::time
);

has jump_dt => (
is => 'rw',
isa => 'Num',
default => Time::HiRes::time
);

has jumping => (
is => 'rw',
isa => 'Num',
default => 0
);

has screen_w => (
is => 'rw',
isa => 'Num',
required => 1
);

has screen_h => (
is => 'rw',
isa => 'Num',
required => 1
);

has map_width => (
is => 'rw',
isa => 'Num',
required => 1
);

has map_height => (
is => 'rw',
isa => 'Num',
required => 1
);

has map_ref => (
is => 'rw',
isa => 'HashRef[Num]',
required => 1
);

sub get_pos_x {
    return shift->pos->[0];
}

sub get_pos_y {
    return shift->pos->[1];
}

sub reset_velocity {
    shift->velocity(6);
}

sub calc_map_pos {
    my ($self) = @_;
    my ($pos_x, $pos_y) = @{$self->pos}[0..1];
    my $x = (($pos_x < $self->screen_w/2) || ($self->screen_w >= $self->map_width)) ? $pos_x : $pos_x - $self->screen_w/2 > $self->map_width - $self->screen_w ? $pos_x - ($self->map_width - $self->screen_w) : $self->screen_w/2;

    my $y = (($pos_y < $self->screen_h/2) || ($self->screen_h >= $self->map_height)) ? $pos_y : $pos_y - $self->screen_h/2 > $self->map_height - $self->screen_h ? $pos_y - ($self->map_height - $self->screen_h) : $self->screen_h/2;

    @{$self->map_pos}[0..1] = ($x, $y);
    return $self->map_pos;
}

sub draw {
    my ($self, $display_surface_ref) = @_;
    my $src;
    if ($self->step_x > 0) {
        $src = $self->look_sprites->[LOOK_AT_RIGHT];
        $src->[0] = 32*$self->sprite_index;
    } elsif ($self->step_x < 0) {
        $src = $self->look_sprites->[LOOK_AT_LEFT];
        $src->[0] = 32*$self->sprite_index;
    } else {
        $src = $self->look_sprites->[LOOK_AT_ME];
    }

    $display_surface_ref->blit_by($self->sprites, $src, $self->calc_map_pos);
}

sub update_pos {
    my ($self, $new_dt) = @_;
    my ($x, $y) = @{$self->pos}[0..1];

    if ($self->step_x != 0) {
        my $new_x = $x + $self->step_x_speed*$self->step_x;
        if ($new_x >= 0 && $new_x <= $self->map_width-32) {
            if ($self->step_x == 1) {
                if (!$self->is_map_val($new_x+32, $y+($self->jumping ? 0 : 32))) {
                    $self->pos->[0] = $new_x;
                } else {
                    $self->pos->[0] = 32*(int($new_x/32));
                }
            } else {
                if (!$self->is_map_val($new_x, $y+($self->jumping ? 0 : 32))) {
                    $self->pos->[0] = $new_x;
                } else {
                    $self->pos->[0] = 32*(int($new_x/32)+1);
                }
            }

            if (!$self->jumping) {
                if ($self->step_x == 1 && !$self->is_map_val($self->pos->[0]+12, $y+64) || $self->step_x == -1 && !$self->is_map_val($self->pos->[0]+20, $y+64)) {

                    $self->jumping(1);
                    $self->velocity(0);
                    $self->jump_dt(Time::HiRes::time);
                }
            }
        }
    }

    if ($self->jumping) {
        # failing

        if (!$self->velocity) {
            #if ($self->is_map_val($self->pos->[0]+8, $self->pos->[1]+1) || $self->is_map_val($self->pos->[0]+32-8, $self->pos->[1]+1)) {
            #    $self->jumping(0);
            #} else {
            my $new_y = 5 + $y + 2*(9.81*(($new_dt - $self->jump_dt)**2));
            my $test_y = $y;
            my $catched_thru_pass = 0;

            while ($test_y < $new_y) {

                if ($self->step_x == 0) {
                    if ($self->is_map_val($self->pos->[0], $test_y)) {
                        $self->pos->[0] = (1 + int($self->pos->[0]/32)) * 32;
                    } elsif ($self->is_map_val($self->pos->[0]+32, $test_y)) {
                        $self->pos->[0] = int($self->pos->[0]/32) * 32;
                    }
                }

                if ($self->step_x == 1 && $self->is_map_val($self->pos->[0]+20, $test_y+32) || $self->step_x == -1 && $self->is_map_val($self->pos->[0]+8, $test_y+32) || $self->step_x == 0 && $self->is_map_val($self->pos->[0]+16, $test_y+32)) {
                    $self->pos->[1] = int($test_y - $test_y%32);
                    $self->jumping(0);

                    $catched_thru_pass = 1;
                    last;
                } else {
                    $test_y += 8;
                }
            }

            if (!$catched_thru_pass) {
                $self->pos->[1] = $new_y;
            }
            #}
        } else {
            # jumping up
            if ($self->pos->[1] % 32 == 0 && $self->is_map_val($self->pos->[0], $self->pos->[1]) && $self->is_map_val($self->pos->[0], $self->pos->[1]-1) && $self->is_map_val($self->pos->[0]+32, $self->pos->[1])) {
                $self->jumping(0);
            } else {

                my $new_velocity = $self->velocity - 3.6*($new_dt - $self->jump_dt);
                if ($new_velocity < 0) {
                    $new_velocity = 0;
                }

                my $new_y = $self->pos->[1] - $new_velocity;
                if (!$self->is_map_val($self->pos->[0], $new_y) && !$self->is_map_val($self->pos->[0]+31, $new_y)) {
                    $self->pos->[1] = $new_y;
                    $self->velocity($new_velocity);
                } else {
                    $self->velocity(0);
                }
            }
        }
    }
}

sub is_map_val {
    my ($self, $x, $y) = @_;

    my $index = int($x/32) + int(($self->map_height-$y)/32)*96;
    return exists $self->map_ref->{$index};
}

sub update_index {
    my ($self, $new_dt) = @_;
    if ($new_dt - $self->sprite_dt >= 0.1) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == 3) {
            $self->{sprite_index} = 0;
        }
    }
}

sub _build_sprites {
    return TextureManager->instance->get('MAIN_CHARACTER');
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
