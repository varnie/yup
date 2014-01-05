package AnimatedSprite;

use strict;
use warnings;
use 5.010;

use Mouse;
use TextureManager;
use Time::HiRes;
use Sprite;
use Loop::Constants;
extends 'Sprite';

has sprite_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time,
    lazy => 1
);

has speed_change_dt => (
    is => 'rw',
    isa => 'Num',
    default => 0.16,
);

has sprites_count => (
    is => 'rw',
    isa => 'Int',
    default => 1
);

has sprite_index => (
    is => 'rw',
    isa => 'Int',
    default => 0
);

sub update_index {
    my ($self, $new_dt) = @_;

    if ($new_dt - $self->sprite_dt >= $self->speed_change_dt) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == $self->sprites_count) {
            $self->{sprite_index} = 0;
        }

        $self->{cur_render_rect} = [@{$self->render_rect}];
        $self->cur_render_rect->[0] = $self->render_rect->[0] + $SPRITE_W*$self->{sprite_index};
    }
}

sub draw {
    my ($self, $display_surface, $map_pos) = @_;
    $display_surface->blit_by($self->img, $self->cur_render_rect, $map_pos);
}

sub _build_img {
    TextureManager->instance->get('WATER');
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
