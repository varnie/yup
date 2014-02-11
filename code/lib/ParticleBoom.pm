package ParticleBoom;

use 5.010;
use strict;
use warnings;

use Mouse;
use SDL::Image;
use SDL::Video;
use TextureManager;
use Loop::Constants;
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

has is_fast => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

has ['newx', 'newy'] => (
    is => 'rw',
    isa => 'Num'
);

has ['vel_x', 'vel_y', 'acc_x', 'acc_y'] => (
    is => 'rw',
    isa => 'Num'
);

sub draw {

}

sub update {
    my ($self, $dt_diff) = @_;

    $self->{vel_x} += $self->acc_x*$dt_diff;
    $self->{vel_y} += $self->acc_y*$dt_diff;
    $self->{newx} += $self->vel_x*$dt_diff;
    $self->{newy} += $self->vel_y*$dt_diff;

    $self->{ttl} -= ($self->is_fast ? 1 : 0.05);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
