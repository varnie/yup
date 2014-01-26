package ParticleBoom;

use 5.010;
use strict;
use warnings;

use Mouse;
use SDL::Image;
use SDL::Video;
use TextureManager;
use ParticleBase;
extends 'ParticleBase';

has '+ttl' => (
    default => sub { int(rand(75)) + 25 }
);

has src_pos => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    required => 1
);

has ['vx', 'vy'] => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

has is_fast => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

sub draw {

}

sub update {
    my ($self) = @_;

    if ($self->is_fast) {
        $self->{x} += $self->vx*2;
        $self->{y} += $self->vy*2;

        $self->{ttl} -= int(rand(4));
    } else {
        $self->{x} += $self->vx;
        $self->{y} += $self->vy;

        --$self->{ttl};
    }

}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
