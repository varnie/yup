package TextureManager;

use Mouse;
use base 'Class::Singleton';
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use Carp qw/croak/;
use 5.010;

use SDL::Image;

use constant TEXTURE_NAMES => {
    WATER => dirname(rel2abs($0)) . '/../tiles/waterstrip11.png',
    MAIN_CHARACTER =>  dirname(rel2abs($0)) .'/../tiles/RE1_Sprites_v1_0_by_DoubleLeggy.png',
    TILES => dirname(rel2abs($0)) .'/../tiles/JnRTiles.png',
    CLOUDS => dirname(rel2abs($0)) .'/../tiles/cloud_new1.png',
    MOUNTAINS => dirname(rel2abs($0)) .'/../tiles/mountains_new1.png',
    FOREST => dirname(rel2abs($0)) .'/../tiles/forest_new.png'
};

has textures => (
    is => 'ro',
    isa => 'HashRef[SDL::Surface]',
    default => sub { {} }
);

sub get {
    my ($self, $name) = (shift, shift);
    if (exists TEXTURE_NAMES->{$name}) {
        if (exists $self->{textures}->{$name}) {
            return $self->{textures}->{$name};
        } else {
            croak(SDL::get_error) unless return $self->{textures}->{$name} = SDL::Image::load(TEXTURE_NAMES->{$name});
        }
    } else {
        croak("Constant `$name` is not declared.");
    }
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
