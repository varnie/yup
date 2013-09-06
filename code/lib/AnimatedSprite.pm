package AnimatedSprite;

use Mouse;
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use Time::HiRes;
use Carp qw/croak/;
use 5.010;

has sprites => (
    is => 'ro',
    isa => 'SDL::Surface',
    lazy => 1,
    builder => '_build_sprites'
);

has sprites_count => (
    is => 'rw',
    isa => 'Num',
    default => 1
);

has sprite_index => (
    is => 'ro',
    isa => 'Num',
    default => 0
);

has sprite_dt => (
    is => 'rw',
    isa => 'Num',
    default => Time::HiRes::time
);

has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[0, 0, 32, 32]}
    );

sub draw {
    my ($self, $display_surface_ref) = (shift, shift);
    ${$display_surface_ref}->blit_by($self->sprites, $self->pos, shift);
}

sub update_index {
    my ($self, $new_dt) = (shift, shift);
    if ($new_dt - $self->sprite_dt >= 0.18) {
        $self->sprite_dt($new_dt);
        if (++$self->{sprite_index} == $self->sprites_count) {
            $self->{sprite_index} = 0;
        }
        $self->pos->[0] = 32*$self->{sprite_index};
    }
}

sub _build_sprites {
    my $res = SDL::Image::load(dirname(rel2abs($0)) . '/../tiles/waterstrip11.png');
    croak(SDL::get_error) unless ($res);
    return $res;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
