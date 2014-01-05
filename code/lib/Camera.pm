package Camera;

use strict;
use warnings;
use 5.010;

use Mouse;

has 'sprite_2_follow' => (
    is => 'rw',
    isa => 'Sprite',
    required => 1
);

has ['calc_x', 'calc_y'] =>  (
    is => 'rw',
    isa => 'Num'
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

sub update {
    my ($self) = @_;

    my ($follow_x, $follow_y) = ($self->sprite_2_follow->x, $self->sprite_2_follow->y);
    state $half_screen_w = $self->screen_w/2;
    state $half_screen_h = $self->screen_h/2;

    my $map_offset_x = do {
        if ($follow_x <= $half_screen_w) {
            0;
        } elsif ($follow_x <= $self->map_width - $half_screen_w) {
            $follow_x - $half_screen_w;
        } else {
            $self->map_width - $self->screen_w;
        }
    };

    my $map_offset_y = do {
        if ($follow_y <= $half_screen_h) {
            0;
        } elsif ($follow_y <= $self->map_height - $half_screen_h) {
            $follow_y - $half_screen_h;
        } else {
            $self->map_height - $self->screen_h;
        }
    };

    $self->calc_x($map_offset_x);
    $self->calc_y($map_offset_y);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
