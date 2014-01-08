package ParticleBloodSplatters;

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

has red => (
    is => 'rw',
    isa => 'Num',
    lazy => 1,
    builder => sub {
        int(2.55 * $_[0]->ttl);
    }
);

sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;

    my $src_rect = SDL::Rect->new(0, 0, $self->size, $self->size);
    my $dst_rect = SDL::Rect->new($self->x - $map_offset_x, $self->y - $map_offset_y, $self->size, $self->size);

    my $aux_surface = TextureManager->instance->get('AUX_SURFACE');
    state $aux_surface_format = $aux_surface->format;

    SDL::Video::fill_rect($aux_surface, $src_rect, SDL::Video::map_RGBA($aux_surface_format, $self->red, $self->green, $self->blue, $self->red));
    SDL::Video::blit_surface($aux_surface, $src_rect, $display_surface, $dst_rect);
}

sub update {
    my ($self) = @_;

    $self->{y} += int(rand($self->size/2))+$self->size;
    my $cur_ttl = ($self->{ttl} -= int(rand(4)));
    $self->red(int(2.55*$cur_ttl));
    $self->size(int($cur_ttl/16.6));
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
