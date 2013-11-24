package Particle;

use 5.010;
use strict;
use warnings;

use Mouse;

use SDL::Image;
use SDL::Video;

use TextureManager;

has ttl => (
    is => 'rw',
    isa => 'Num',
    default => sub {  int(rand(75)) + 25 }
);

has red => (
    is => 'rw',
    isa => 'Num',
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        return int(2.55 * $self->ttl);
    }
);

has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[0, 0]}
);

has size => (
    is => 'rw',
    isa => 'Num',
    default => 6
);

sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;

    my $src_rect = SDL::Rect->new($self->pos->[0] - $map_offset_x, $self->pos->[1] - $map_offset_y, $self->size, $self->size);

    my $aux_surface = TextureManager->instance->get('AUX_SURFACE');
    SDL::Video::fill_rect($aux_surface, $src_rect, SDL::Video::map_RGBA($aux_surface->format(), $self->red, 0, 0, $self->red));
    SDL::Video::blit_surface($aux_surface, $src_rect, $display_surface, $src_rect);

}

sub update {
    #$_[0]->pos->[1] += int(rand(10));
    #$_[0]->pos->[0] += int(rand(5)) - 2;
    
    $_[0]->pos->[1] += int(rand($_[0]->size/2))+$_[0]->size;
    #$_[0]->pos->[0] += int(rand(2)) == 1 ? 1 : -1;
    
    #$_[0]->pos->[0] += int(rand(2)) == 1 ? int(rand(5)) - 2 : -int(rand(5)) - 2;

    my $cur_ttl = $_[0]->ttl($_[0]->ttl-int(rand(4)));
    $_[0]->red(int(2.55*$cur_ttl));

    $_[0]->size(int($cur_ttl/16.6));

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
