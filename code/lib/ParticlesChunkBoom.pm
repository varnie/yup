package ParticlesChunkBoom;

use 5.010;
use strict;
use warnings;

use Mouse;
use ParticlesChunkBase;
use ParticleBoom;
extends 'ParticlesChunkBase';

#TODO:
sub init {
    my ($self, $center_x, $center_y, $rects, $img) = @_;

    foreach my $rect (@{$rects}) {
        my $is_fast = int(rand(2));
        push @{$self->items}, ParticleBoom->new(
            x => $center_x,
            y => $center_y,
            src_rect => $rect,
            img => $img,
            size => 2,
            vx => rand(20) - 10 + ($is_fast ? rand(10) : 0),
            vy => rand(20) - 10 + ($is_fast ? rand(10) : 0),
            is_fast => $is_fast
            );
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
