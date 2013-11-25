package ParticlesChunkBloodSplatters;

use 5.010;
use strict;
use warnings;

use Mouse;

use SDL::Video;

use ParticlesChunkBase;
extends 'ParticlesChunkBase';

use ParticleBloodSplatters;

use Carp qw/croak/;

#override method
sub init {
    my ($self, $center_x, $center_y) = @_;
    foreach my $i (1..$self->count) {
        push @{$self->items}, ParticleBloodSplatters->new(pos => [$center_x + 8 + int(rand(16)), $center_y + int(rand(20))]);
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
