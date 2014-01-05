package RidingBlock;

use strict;
use warnings;
use 5.010;

use Time::HiRes;
use Mouse;
use Moose::Util::TypeConstraints;
use TextureManager;
use SDL::Video;
use Loop::Constants;
use Sprite;
extends 'Sprite';

has moving_type => (
    is => 'rw',
    isa => enum([values($MOVEMENT)]),
    default => $MOVEMENT->{UP}
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

has '+render_rect' => (
    default => sub { [$SPRITE_W*7, 0, $SPRITE_W, $SPRITE_H] }
);

sub update_pos {
    my ($self, $new_dt) = @_;

    my $dt_diff = $new_dt - $self->move_dt;
    my $half_duration = $self->duration/2;

    if ($self->moving_type == $MOVEMENT->{UP}) {
        $self->y($self->y - $self->step_speed*$dt_diff);
        if ($self->y <= $self->initial_pos->[1] - $half_duration) {
            $self->y($self->initial_pos->[1] - $half_duration);
            $self->moving_type($MOVEMENT->{DOWN});
        }
    } elsif ($self->moving_type == $MOVEMENT->{DOWN}) {
        $self->y($self->y + $self->step_speed*$dt_diff);

        if ($self->y >= $self->initial_pos->[1] + $half_duration) {
            $self->y($self->initial_pos->[1] + $half_duration);
            $self->moving_type($MOVEMENT->{UP});
        }
    } elsif ($self->moving_type == $MOVEMENT->{LEFT}) {
        $self->x($self->x - $self->step_speed*$dt_diff);

        if ($self->x <= $self->initial_pos->[0] - $half_duration) {
            $self->x($self->initial_pos->[0] - $half_duration);
            $self->moving_type($MOVEMENT->{RIGHT});
        }
    } else {
        $self->x($self->x + $self->step_speed*$dt_diff);

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
        $self->render_rect,
        [$self->x-$self->half_w-$map_offset_x, $self->y-$self->half_h-$map_offset_y, $self->w, $self->h]);
}

sub is_horizontal_move {
    my ($self) = @_;
    return $self->moving_type == $MOVEMENT->{LEFT} || $self->moving_type == $MOVEMENT->{RIGHT};
}

sub _build_img {
    TextureManager->instance->get('TILES');
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    if (!exists($args{initial_pos})) {
        $args{initial_pos} = [$args{x}, $args{y}];
    }

    return $class->$orig(%args);
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
