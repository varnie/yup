package Character;

use Mouse;
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use Time::HiRes;
use Carp qw/croak/;
use 5.010;

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
    builder => '_build_sprites'
);

has sprite_index => (
    is => 'ro',
    isa => 'Num',
    default => 0
);

has sprite_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time
);

has step_x => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has step_x_speed => (
    is => 'rw',
    isa => 'Num',
    default => 3.25
);

has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[50, 282-32, 32, 32]}
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
    my $self = shift;
    my ($pos_x, $pos_y) = @{$self->pos}[0..1];
    my $x = (($pos_x < $self->screen_w/2) || ($self->screen_w >= $self->map_width)) ? $pos_x : $pos_x - $self->screen_w/2 > $self->map_width - $self->screen_w ? $pos_x - ($self->map_width - $self->screen_w) : $self->screen_w/2;
    @{$self->map_pos}[0..1] = ($x, $pos_y);
    return $self->map_pos;
}

sub draw {
    my ($self, $display_surface_ref) = (shift, shift);
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

    ${$display_surface_ref}->blit_by($self->sprites, $src, $self->calc_map_pos);
}

sub update_pos {
    my ($self, $new_dt) = (shift, shift);
    my ($x, $y) = ($self->pos->[0], $self->pos->[1]);

    if ($self->step_x != 0) {
        my $new_x = $x + $self->step_x_speed*$self->step_x;
        if ($new_x >= 0 && $new_x <= $self->map_width-32) {
            if ($self->step_x == 1) {
                if (!$self->is_map_val($new_x+32, $y)) {
                    $self->pos->[0] = $new_x;
                } else {
                    $self->pos->[0] = 32*(int($new_x/32));
                }
            } else {
                if (!$self->is_map_val($new_x, $y)) {
                    $self->pos->[0] = $new_x;
                } else {
                    $self->pos->[0] = 32*(int($new_x/32)+1);
                }
            }

            if (!$self->jumping && (!$self->is_map_val($self->pos->[0]+8, $self->pos->[1]+32) || !$self->is_map_val($self->pos->[0]+8, $self->pos->[1]+32))) {
                $self->jumping(1);
                $self->velocity(0);
                $self->jump_dt(Time::HiRes::time);
            }
        }
    }

    if ($self->jumping) {
        # failing

        if (!$self->velocity) {

            #if ($self->is_map_val($self->pos->[0]+8, $self->pos->[1]+1) || $self->is_map_val($self->pos->[0]+32-8, $self->pos->[1]+1)) {
                #$self->jumping(0);
            #} else {
                my $new_y = $y + 2*(9.81*(($new_dt - $self->jump_dt)**2));
                my $test_y = $self->pos->[1];
                my $catched_thru_pass = 0;
                my $diff = $self->screen_h - 768;

                while ($test_y < $new_y) {

                    if ($self->is_map_val($self->pos->[0], $self->pos->[1])) {
                        $self->pos->[0] = int(1 + $self->pos->[0]/32) * 32;
                    } elsif ($self->is_map_val($self->pos->[0]+32, $self->pos->[1])) {
                        $self->pos->[0] = int($self->pos->[0]/32) * 32;
                    }

                    if ($self->is_map_val($self->pos->[0]+8, $test_y+32) || $self->is_map_val($self->pos->[0]+24, $test_y+32)) {
                        $self->pos->[1] = $test_y - ($test_y - $diff)%32;
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

sub is_map_val {
    my ($self, $x, $y) = (shift, shift, shift);
    my $aux_y = $self->screen_h-768;
    #my $index = int($x/32)*24 + int(($y - $aux_y)/32);
    return ($y >= $aux_y) && $self->map_ref->{int($x/32)*24 + int(($y-$aux_y)/32)};
}

sub update_index {
    my ($self, $new_dt) = (shift, shift);
    if ($new_dt - $self->sprite_dt >= 0.1) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == 3) {
            $self->{sprite_index} = 0;
        }
    }
}

sub _build_sprites {
    my $res = SDL::Image::load(dirname(rel2abs($0)) . '/../tiles/RE1_Sprites_v1_0_by_DoubleLeggy.png');
    croak(SDL::get_error) unless ($res);
    return $res;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
