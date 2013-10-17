package TextureManager;

use 5.010;
use strict;
use warnings;

use Mouse;
use base 'Class::Singleton';
use File::Basename;
use File::Spec;
use Carp qw/croak/;

use SDL::Image;

use constant TEXTURE_NAMES => do {
    my ($vol, $dir, $file) = File::Spec->splitpath(dirname($0));
    {
        WATER => File::Spec->catfile($vol, $dir, 'tiles', 'waterstrip11.png'),
        MAIN_CHARACTER =>  File::Spec->catfile($vol, $dir, 'tiles', 'RE1_Sprites_v1_0_by_DoubleLeggy.png'),
        TILES => File::Spec->catfile($vol, $dir, 'tiles', 'JnRTiles.png'),
        CLOUDS => File::Spec->catfile($vol,  $dir, 'tiles', 'cloud_new1.png'),
        MOUNTAINS => File::Spec->catfile($vol, $dir, 'tiles', 'mountains_new1.png'),
        FOREST => File::Spec->catfile($vol, $dir, 'tiles', 'forest_new.png')
    }
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
