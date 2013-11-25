package ParticleCircle;

use 5.010;
use strict;
use warnings;

use Mouse;

use SDL::Image;
use SDL::Video;

use TextureManager;

use ParticleBase;
extends 'ParticleBase';

has degrees => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

has radius => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

has ttl => (
    is => 'rw',
    isa => 'Num',
    default => sub { int(rand(10)) + 90 }
);

has red => (
    is => 'rw',
    isa => 'Num',
    lazy => 1,
    builder => sub {
        int(2.55 * $_[0]->ttl);
    }
);

has initial_pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]'
);

#override method
sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;
    say $self->initial_pos->[0], " ", $self->initial_pos->[1];
    my $src_rect = SDL::Rect->new(0, 0, $self->size, $self->size);
    my $dst_rect = SDL::Rect->new($self->initial_pos->[0] + $self->pos->[0] - $map_offset_x, $self->initial_pos->[1] + $self->pos->[1] - $map_offset_y, $self->size, $self->size);

    my $aux_surface = TextureManager->instance->get('AUX_SURFACE');
    state $aux_surface_format = $aux_surface->format;

    SDL::Video::fill_rect($aux_surface, $src_rect, SDL::Video::map_RGBA($aux_surface_format, $self->red, $self->green, $self->blue, $self->red));
    SDL::Video::blit_surface($aux_surface, $src_rect, $display_surface, $dst_rect);
}

#override method
sub update {
    my ($self) = @_;

    $self->radius($self->radius+1);
    $self->pos->[0] = $self->radius * cos($self->degrees);
    $self->pos->[1] = $self->radius * sin($self->degrees);

    my $cur_ttl = $self->ttl($self->ttl-3);
    $self->red(int(2.55*$cur_ttl));
    $self->size(int($cur_ttl/16.6));
}

around BUILDARGS => sub {

    my ($orig, $class, %args) = @_;
    if (!exists($args{initial_pos})) {
        $args{initial_pos} = [@{$args{pos}}];
    }

    return $class->$orig(%args);
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
