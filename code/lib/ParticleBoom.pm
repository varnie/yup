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

#has ['vy', 'coeff', 'degrees'] => (
#    is => 'rw',
#    isa => 'Num',
#    required => 1
#);

#has initial_pos => (
#    is => 'ro',
#    isa => 'ArrayRef[Num]'
#);

#has cos_val => (
#    is => 'ro',
#    isa => 'Num'
#);
#
#has sin_val => (
#    is => 'ro',
#    isa => 'Num'
#);

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
    my ($self) = @_;

    $self->{vel_x} += $self->acc_x;
    $self->{vel_y} += $self->acc_y;
    $self->{newx} += $self->vel_x;
    $self->{newy} += $self->vel_y;

    #$self->{acc_y} -= 0.5;
    #$self->{vy} += $self->is_fast ? $self->acc_y*0.4 : $self->acc_y*0.8;

    #$self->{newx} = $self->initial_pos->[0] + $self->cos_val*$self->coeff*($self->is_fast ? 8 : 16);
    #$self->{newy} = $self->initial_pos->[1] - $self->sin_val*$self->coeff - $self->vy + 20*abs($self->coeff);

    #$self->{coeff} += 0.25;

    $self->{ttl} -= ($self->is_fast ? 2 : 1);
}

#around BUILDARGS => sub {
#
#    my ($orig, $class, %args) = @_;
#    #if (!exists($args{initial_pos})) {
#        #$args{initial_pos} = [$args{x}, $args{y}];
#        $args{newx} = $args{x};
#        $args{newy} = $args{y};
#    #}
#    #if (!exists($args{cos_val})) {
#    #    $args{cos_val} = cos($args{degrees}*$RADIAN);
#    #}
#    #if (!exists($args{sin_val})) {
#    #    $args{sin_val} = sin($args{degrees}*$RADIAN);
#    #}
#
#    return $class->$orig(%args);
#};

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
