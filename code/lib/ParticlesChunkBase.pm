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

has move_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time#,
#    lazy => 1
);

has speed_change_dt => (
    is => 'rw',
    isa => 'Num',
    default => 0.02
);

sub init {
    confess shift, " should have defined `init`";
}

sub draw {
    my ($self, $display_surface, $map_offset_x, $map_offset_y) = @_;
    foreach (@{$self->items}) {
        if ($_->ttl > 0) {
            $_->draw($display_surface, $map_offset_x, $map_offset_y);
        }
    }
}

sub update {
    my ($self, $new_dt) = @_;

    my $dt_diff = $new_dt - $self->move_dt;
    if ($dt_diff >= $self->speed_change_dt) {
        $self->move_dt($new_dt);

        my $alive_cnt = 0;
        foreach (@{$self->items}) {
            if ($_->ttl > 0) {
                $_->update($dt_diff);
                ++$alive_cnt;
            }
        }

        $self->is_dead(1) unless $alive_cnt;
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
