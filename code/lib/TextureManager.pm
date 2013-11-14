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
use SDL::Video;

use constant TEXTURE_NAMES => do {
    my @dirs = File::Spec->splitdir(File::Spec->rel2abs(__FILE__));
    @dirs = @dirs[0.. (scalar @dirs)-4];

    {
        WATER => File::Spec->catfile(@dirs, 'tiles', 'waterstrip11.png'),
        'MAIN_CHARACTER@BAD_GUY' => File::Spec->catfile(@dirs, 'tiles', 'RE1_Sprites_v1_0_by_DoubleLeggy.png'),
        TILES => File::Spec->catfile(@dirs, 'tiles', 'JnRTiles.png'),
        CLOUDS => File::Spec->catfile(@dirs, 'tiles', 'cloud_new1.png'),
        MOUNTAINS => File::Spec->catfile(@dirs, 'tiles', 'mountains_new1.png'),
        FOREST => File::Spec->catfile(@dirs, 'tiles', 'forest_new.png'),
    }
};

has textures => (
    is => 'ro',
    isa => 'HashRef[SDL::Surface]',
    default => sub { {} }
);

sub get {
    my ($self, $name) = @_;

    my ($matched_key) = grep {$_ =~ qr/$name/ } keys TEXTURE_NAMES;

    if ($matched_key) {
        if (exists $self->{textures}->{$matched_key}) {
            return $self->{textures}->{$matched_key};
        } else {
            my $texture_data = SDL::Image::load(TEXTURE_NAMES->{$matched_key});
            croak(SDL::get_error) unless $texture_data;
            $texture_data = SDL::Video::display_format($texture_data);
            croak(SDL::get_error) unless $texture_data;
            if ($name eq 'BAD_GUY') {
                croak(SDL::get_error) if SDL::Video::set_color_key($texture_data, SDL_SRCCOLORKEY
                    , SDL::Video::map_RGB($texture_data->format, 0xFF, 0xFF, 0xFF));
            }
            $self->{textures}->{$matched_key} = $texture_data;

            return $texture_data;
        }
    } else {
        croak("Constant `$name` is not declared and could not be found into the synonyms.");
    }
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
