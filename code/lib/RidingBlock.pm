package RidingBlock;

use strict;
use warnings;
use 5.010;

use Time::HiRes;

use Mouse;
use Moose::Util::TypeConstraints;
use TextureManager;
use CollisionDetector;

use SDL::Video;
use Entity;
use Movable;
extends 'Entity', 'Movable';

use constant MOVEMENT => {
    UP => 1,
    DOWN => 2,
    LEFT => 3,
    RIGHT => 4 
};

has moving_type => (
    is => 'rw',
    isa => enum([values(MOVEMENT)]), #'Num',
    default => MOVEMENT->{UP} #1 #1 = UP; 2 = DOWN; 3 = LEFT; 4 = RIGHT;
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

#override Movable attribute
has look_sprites => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Num]]',
    default => sub {[ [32*7, 0, 32, 32] ]}
);

has step_x_speed => (
    is => 'rw',
    isa => 'Num',
    default => 2
);

#override Movable method
sub update_pos {
    my ($self) = @_;

    my $half_duration = $self->duration/2;

    my $is_vertical_move;

    if ($self->moving_type == MOVEMENT->{UP}) {
        #UP

        $is_vertical_move = 1;

        $self->pos->[1] -= $self->step_x_speed;
        if ($self->pos->[1] <= $self->initial_pos->[1] - $half_duration) {
            $self->pos->[1] = $self->initial_pos->[1] - $half_duration;
            $self->moving_type(MOVEMENT->{DOWN});
        }
    } elsif ($self->moving_type == MOVEMENT->{DOWN}) {
        #DOWN

        $is_vertical_move = 1;

        $self->pos->[1] += $self->step_x_speed;

        if ($self->pos->[1] >= $self->initial_pos->[1] + $half_duration) {
            $self->pos->[1] = $self->initial_pos->[1] + $half_duration;
            $self->moving_type(MOVEMENT->{UP});
        }
    } elsif ($self->moving_type == MOVEMENT->{LEFT}) {
        #LEFT

        $is_vertical_move = 0;

        $self->pos->[0] -= $self->step_x_speed;

        if ($self->pos->[0] <= $self->initial_pos->[0] - $half_duration) {
            $self->pos->[0] = $self->initial_pos->[0] - $half_duration;
            $self->moving_type(MOVEMENT->{RIGHT});
        }
    } else {
        #RIGHT

        $is_vertical_move = 0;

        $self->pos->[0] += $self->step_x_speed;

        if ($self->pos->[0] >= $self->initial_pos->[0] + $half_duration) {
            $self->pos->[0] = $self->initial_pos->[0] + $half_duration;
            $self->moving_type(MOVEMENT->{LEFT});
        }
    }
}

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
    $display_surface_ref->blit_by($self->sprites, $self->look_sprites->[0], $self->calc_map_pos($map_offset_x, $map_offset_y));
}

#new method
sub is_horizontal_move {
    my ($self) = @_;
    return $self->moving_type eq MOVEMENT->{LEFT} || $self->moving_type eq MOVEMENT->{RIGHT};
}

sub _build_sprites {
    return TextureManager->instance->get('TILES');
}

around BUILDARGS => sub {

    my ($orig, $class, %args) = @_;
    if (!exists($args{initial_pos})) {
        $args{initial_pos} = [@{$args{pos}}];
    }

    return $class->$orig(%args);
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
