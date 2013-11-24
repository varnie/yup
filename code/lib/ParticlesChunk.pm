package ParticlesChunk;

use 5.010;
use strict;
use warnings;

use Mouse;
use base 'Class::Singleton';
use File::Basename;
use File::Spec;

use SDL::Image;
use SDL::Video;

use Particle;

has count => (
    is => 'ro',
    isa => 'Num',
    required => 1,
    default => 120
);

has items => (
    is => 'rw',
    isa => 'ArrayRef[Particle]',
    default => sub {[]}
);

sub init {
    my ($self, $center_x, $center_y) = @_;
    foreach my $i (1..$self->count) {
        push @{$self->items}, Particle->new(pos => [$center_x + int(rand(20)), $center_y + int(rand(20))]);
    }
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
    foreach my $item (@{$self->items}) {
        $item->update();
        if ($item->ttl <= 0) {
            splice @{$self->items}, $i, 1;
        }

        ++$i;
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
