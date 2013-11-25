package ParticlesChunkCircles;

use 5.010;
use strict;
use warnings;

use Mouse;

use ParticlesChunkBase;
extends 'ParticlesChunkBase';

use ParticleCircle;

#override method
sub init {
    my ($self, $center_x, $center_y, $radius) = @_;

    my $degrees_per_item = 360 / $self->count;
    foreach my $i (1..$self->count) {
        my $cur_degrees = $degrees_per_item*$i;

        push @{$self->items}, ParticleCircle->new(
            pos => [$center_x + 16, $center_y],
            degrees => $cur_degrees,
            radius => $radius);
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
