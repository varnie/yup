package ParticlesChunkCircles;

use 5.010;
use strict;
use warnings;

use Mouse;
use ParticleCircle;
use ParticlesChunkBase;
extends 'ParticlesChunkBase';

sub init {
    my ($self, $center_x, $center_y, $radius) = @_;

    my $degrees_per_item = int(360 / $self->count);
    foreach my $i (1..$self->count) {

        push @{$self->items}, ParticleCircle->new(
            x => $center_x,
            y => $center_y,
            degrees => $degrees_per_item*$i,
            radius => $radius,
            size => 10);
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
