package RidingBlock;

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
extends 'Entity', 'Movable';

has moving_type => (
    is => 'rw',
    isa => 'Num',
    default => 1 #1 = UP; 2 = DOWN; 3 = LEFT; 4 = RIGHT;
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

    if ($self->moving_type == 1) {
        #UP

        my $new_y = $self->pos->[1] - $self->step_x_speed;
        $self->pos->[1] = $new_y;
        if ($new_y <= $self->initial_pos->[1] - $self->duration) {
            $self->moving_type(2);
        }
    } elsif ($self->moving_type == 2) {
        #DOWN
        
        my $new_y = $self->pos->[1] + $self->step_x_speed;
        $self->pos->[1] = $new_y;

        if ($new_y >= $self->initial_pos->[1]) {
            $self->moving_type(1);
        }
    } #TODO: horisontal movements
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

sub _build_sprites {
    return TextureManager->instance->get('TILES');
}

sub BUILD {
    my ($self, $args) = @_;
    $self->initial_pos([@{$args->{pos}}]);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
