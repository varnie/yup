package AnimatedSprite;

use strict;
use warnings;
use 5.010;

use Time::HiRes;

use Mouse;
use TextureManager;

use Entity;
extends 'Entity';

#override
has sprite_index => (
    is => 'ro',
    isa => 'Num',
    lazy => 1,
    builder => '_build_sprite_index'
);

sub _build_sprite_index {
    return int rand shift->sprites_count;
}

#new attribute
has sprites_count => (
    is => 'rw',
    isa => 'Num',
    default => 1
);

#new attribute
has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[0, 0, 32, 32]}
);

#override
sub draw {
    my ($self, $display_surface_ref, $map_pos) = @_;
    $display_surface_ref->blit_by($self->sprites, $self->pos, $map_pos);
}

#override
sub update_index {
    my ($self, $new_dt) = @_;
    if ($new_dt - $self->sprite_dt >= 0.16) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == $self->sprites_count) {
            $self->{sprite_index} = 0;
        }
        $self->pos->[0] = 32*$self->{sprite_index};
    }
}

#override
sub _build_sprites {
    return TextureManager->instance->get('WATER');
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
