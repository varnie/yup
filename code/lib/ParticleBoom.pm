package ParticleBoom;

use 5.010;
use strict;
use warnings;

use Mouse;
use SDL::Image;
use SDL::Video;
use ParticleBase;
use TextureManager;
extends 'ParticleBase';

has '+ttl' => (
    default => sub { int(rand(75)) + 25 }
);

has src_rect => (
    is => 'ro',
    isa => 'SDL::Rect',
    required => 1
);

has img => (
    is => 'ro',
    isa => 'SDL::Surface',
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

#TODO:
sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;

    my $dst_rect = SDL::Rect->new($self->x - $map_offset_x, $self->y - $map_offset_y, $self->size, $self->size);
    my $aux_surface_for_boom = TextureManager->instance->get('AUX_SURFACE_FOR_BOOM');

    my $aux_dst_rect = SDL::Rect->new(0, 0, $self->size, $self->size);
    SDL::Video::set_alpha($aux_surface_for_boom, SDL_SRCALPHA, 2.55*$self->ttl);
    SDL::Video::blit_surface($self->img, $self->src_rect, $aux_surface_for_boom, $aux_dst_rect);

    $display_surface->blit_by($aux_surface_for_boom, $aux_dst_rect, $dst_rect);
}

#TODO:
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
