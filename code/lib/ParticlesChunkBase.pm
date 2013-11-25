package ParticlesChunkBase;

use 5.010;
use strict;
use warnings;

use Mouse;

use SDL::Image;
use SDL::Video;

use ParticleBase;

has count => (
    is => 'ro',
    isa => 'Num',
    required => 1,
    default => 20
);

has items => (
    is => 'rw',
    isa => 'ArrayRef[ParticleBase]',
    default => sub {[]}
);

has is_dead => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

sub init {
    confess shift, " should have defined `update_index`";
}

sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;
    foreach my $item (@{$self->items}) {
        $item->draw($display_surface, $map_offset_x, $map_offset_y);
    }
}

sub update {
    my ($self) = @_;

    my $i = 0;
    while ($i <= $#{$self->items}) {
        my $item = @{$self->items}[$i];
        $item->update;
        if ($item->ttl <= 0) {
            splice @{$self->items}, $i, 1;
        } else {
            ++$i;
        }
    }

    $self->is_dead(1) unless @{$self->items};
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
