package ParticlesChunkBloodSplatters;

use 5.010;
use strict;
use warnings;

use Mouse;
use Loop::Constants;
use ParticleBloodSplatters;
use ParticlesChunkBase;
extends 'ParticlesChunkBase';

sub init {
    my ($self, $center_x, $center_y) = @_;
    foreach my $i (1..$self->count) {
        push @{$self->items}, ParticleBloodSplatters->new(x => $center_x - $SPRITE_HALF_W/2 + int(rand($SPRITE_HALF_W)), y => $center_y + int(rand(20)));
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
