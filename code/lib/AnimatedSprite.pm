package AnimatedSprite;

use strict;
use warnings;
use 5.010;

use Mouse;
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use Time::HiRes;

use TextureManager;

has sprites => (
    is => 'ro',
    isa => 'SDL::Surface',
    lazy => 1,
    builder => '_build_sprites',
    init_arg => undef
);

has sprites_count => (
    is => 'rw',
    isa => 'Num',
    default => 1
);

has sprite_index => (
    is => 'ro',
    isa => 'Num',
    lazy => 1,
    default => sub { return int rand shift->sprites_count; }
);

has sprite_dt => (
    is => 'rw',
    isa => 'Num',
    lazy => 1,
    default => Time::HiRes::time
);

has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[0, 0, 32, 32]}
    );

sub draw {
    my ($self, $display_surface_ref, $map_pos) = @_;;
    $display_surface_ref->blit_by($self->sprites, $self->pos, $map_pos);
}

sub update_index {
    my ($self, $new_dt) = @_;
    if ($new_dt - $self->sprite_dt >= 0.16) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == $self->sprites_count) {
            $self->{sprite_index} = 0;
        }
        $self->pos->[0] = 32*$self->{sprite_index};
    }
}

sub _build_sprites {
    return TextureManager->instance->get('WATER');
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
