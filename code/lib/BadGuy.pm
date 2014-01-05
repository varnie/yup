package BadGuy;

use strict;
use warnings;
use 5.010;

use Mouse;
use TextureManager;
use CollisionDetector;
use Camera;
use RidingBlock;
use AnimatedSprite;
use Moose::Util::TypeConstraints;
use Loop::Constants;
use SDL::Video;
extends 'AnimatedSprite';

has moving_type => (
    is => 'rw',
    isa => enum([values($MOVEMENT)]),
    default => $MOVEMENT->{LEFT}
);

has look_sprites => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Int]]',
    default => sub {
        [
            [32*6, 32*2, 32, 32], #LOOK_AT_RIGHT
            [32*6, 32, 32, 32], #LOOK_AT_LEFT
            [32*6, 0, 32, 32] #IDLE
        ]
    }
);

has duration => (
    is => 'rw',
    isa => 'Num',
    default => 10
);

has initial_pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]'
);

has step_speed => (
    is => 'rw',
    isa => 'Num',
    default => 100
);

has move_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time
);

sub update_index {
    my ($self, $new_dt) = @_;

    if ($new_dt - $self->sprite_dt >= $self->speed_change_dt) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == $self->sprites_count) {
            $self->{sprite_index} = 0;
        }

        $self->render_rect($self->look_sprites->[$self->moving_type == $MOVEMENT->{RIGHT} ? $LOOK_AT_RIGHT : $LOOK_AT_LEFT]);
        $self->{cur_render_rect} = [@{$self->render_rect}];
        $self->cur_render_rect->[0] = $self->render_rect->[0] + $SPRITE_W*$self->sprite_index;
    }
}

sub update_pos {
    my ($self, $new_dt) = @_;

    my $dt_diff = $new_dt - $self->move_dt;
    my $half_duration = $self->duration/2;

    if ($self->moving_type == $MOVEMENT->{LEFT}) {
        $self->{x} -= $self->step_speed*$dt_diff;

        if ($self->x <= $self->initial_pos->[0] - $half_duration) {
            $self->x($self->initial_pos->[0] - $half_duration);
            $self->moving_type($MOVEMENT->{RIGHT});
        }
    } else {
        $self->{x} += $self->step_speed*$dt_diff;

        if ($self->x >= $self->initial_pos->[0] + $half_duration) {
            $self->x($self->initial_pos->[0] + $half_duration);
            $self->moving_type($MOVEMENT->{LEFT});
        }
    }

    #update the move_dt
    $self->move_dt($new_dt);
}

sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;

    $display_surface->blit_by(
        $self->img,
        $self->cur_render_rect,
        [$self->x-$self->half_w-$map_offset_x, $self->y-$self->half_h-$map_offset_y, $self->w, $self->h]);
}

sub _build_img {
    TextureManager->instance->get('BAD_GUY');
}

sub BUILD {
    my ($self) = @_;

    $self->speed_change_dt(0.1);
    $self->sprites_count(3); #3 per animation
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    if (!exists($args{initial_pos})) {
        $args{initial_pos} = [$args{x}, $args{y} ];
    }

    return $class->$orig(%args);
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
