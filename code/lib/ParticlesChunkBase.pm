package ParticlesChunkBase;

use 5.010;
use strict;
use warnings;

use Mouse;
use SDL::Image;
use SDL::Video;
use ParticleBase;
use Time::HiRes;

has count => (
    is => 'ro',
    isa => 'Num',
    required => 1,
    default => 10
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

has sprite_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time,
    lazy => 1
);

has speed_change_dt => (
    is => 'rw',
    isa => 'Num',
    default => 0.16,
);

sub init {
    confess shift, " should have defined `init`";
}

sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;
    foreach my $item (@{$self->items}) {
        $item->draw($display_surface, $map_offset_x, $map_offset_y);
    }
}

sub update {
    my ($self, $new_dt) = @_;

    if ($new_dt - $self->sprite_dt >= 0.05) {
        $self->sprite_dt($new_dt);

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
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
