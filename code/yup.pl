#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Carp qw/croak/;

use SDL;
use SDL::Events;
use SDL::Image;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::VideoInfo;
use SDL::PixelFormat;
use SDLx::App;
use SDLx::Surface;
use SDLx::Text;

use Time::HiRes;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Basename;
use File::Spec;

use Character;
use AnimatedSprite;
use TextureManager;

SDL::init(SDL_INIT_VIDEO);

my $video_info = SDL::Video::get_video_info;
my ($screen_w, $screen_h, $bits_per_pixel) = ($video_info->current_w, $video_info->current_h, $video_info->vfmt->BitsPerPixel);

my $display = SDL::Video::set_video_mode($screen_w, $screen_h, $bits_per_pixel, SDL_SWSURFACE|SDL_ANYFORMAT|SDL_FULLSCREEN);
my $display_surface = SDLx::Surface->new(surface => $display);

my $tiles_surface = TextureManager->instance->get('TILES');

my $sky_surface = TextureManager->instance->get('CLOUDS');
$sky_surface = SDL::Video::display_format($sky_surface);
croak(SDL::get_error) unless $sky_surface;

my $trees_surface = TextureManager->instance->get('FOREST');
$trees_surface = SDL::Video::display_format($trees_surface);
croak(SDL::get_error) unless $trees_surface;

my $mountains_surface = TextureManager->instance->get('MOUNTAINS');

my $m_surface_new = SDLx::Surface->new(width => $mountains_surface->w, height => $mountains_surface->h, flags => SDL_ANYFORMAT & ~(SDL_SRCALPHA));
croak(SDL::get_error) unless $m_surface_new;
croak(SDL::get_error) if SDL::Video::set_color_key($m_surface_new, SDL_SRCCOLORKEY | SDL_RLEACCEL, SDL::Video::map_RGB($m_surface_new->format, 0xf1, 0xcb, 0x86));
SDL::Video::blit_surface($mountains_surface, undef, $m_surface_new, undef);

$mountains_surface = SDL::Video::display_format($m_surface_new);
croak(SDL::get_error) unless $mountains_surface;


my ($map_ref, $max_x, $max_y) = create_map();
my %map = %$map_ref;

my $map_animated_sprites_ref = create_animated_sprites_map();
my %map_animated_sprites = %$map_animated_sprites_ref;

my $whole_map_surface = SDLx::Surface->new(width => $max_x, height => $max_y, flags => SDL_ANYFORMAT & ~(SDL_SRCALPHA));
croak(SDL::get_error) unless $whole_map_surface;
croak(SDL::get_error) if SDL::Video::set_color_key($whole_map_surface, SDL_SRCCOLORKEY | SDL_RLEACCEL,  0);

my $tile_rect = [0, 0, 32, 32];

foreach my $x (0..($max_x/32)-1) {
    foreach my $y (0..($max_y/32)-1) {
        if (exists $map{$y*$max_x/32+$x}) {
            $whole_map_surface->blit_by($tiles_surface, $tile_rect, [$x*32, $max_y-32 - $y*32, 32, 32]);
        }
    }
}

$whole_map_surface = SDL::Video::display_format($whole_map_surface);
croak(SDL::get_error) unless $whole_map_surface;

croak(SDL::get_error) if SDL::Video::flip($whole_map_surface);
#SDL::Video::save_BMP($whole_map_surface, "foo.bmp");

#say 'total ', scalar keys %map;
#say ((scalar keys %map) / 24);
#test

my ($ch, $e, $quit, $time, $aux_time, $FPS) = (
    Character->new(
        screen_w => $screen_w,
        screen_h => $screen_h,
        map_width => $max_x,
        map_height => $max_y,
        map_ref => $map_ref,
        jumping => 1,
        velocity => 0
    ),
    SDL::Event->new,
    0,
    Time::HiRes::time,
    Time::HiRes::time,
    0
);

my $FRAME_RATE = 1000/60;
my $bg_fill_color = SDL::Color->new(241, 203, 144);

my @dirs = File::Spec->splitdir(File::Spec->rel2abs(__FILE__));
@dirs = @dirs[0.. (scalar @dirs)-3];

my $text_obj = SDLx::Text->new(font => File::Spec->catfile(@dirs, 'fonts', 'FreeSerif.ttf'),
    x => 10,
    y => 10);

my $screen_rect = [0, 0, $screen_w, $screen_h];

my $x_per_row = int($max_x/32);
my $y_per_row = int($max_y/32);
my $x_per_screen = int($screen_w/32);
my $y_per_screen = int($screen_h/32);
my @animated_sprites_keys = keys %map_animated_sprites;

while (!$quit) {
    SDL::Events::pump_events();
    while (SDL::Events::poll_event($e)) {
        if ($e->type == SDL_KEYDOWN) {
            my $key_sym = $e->key_sym;
            if ($key_sym == SDLK_ESCAPE) {
                $quit = 1;
            } elsif ($key_sym == SDLK_RIGHT) {
                $ch->step_x(1);
            } elsif ($key_sym == SDLK_LEFT) {
                $ch->step_x(-1);
            } elsif ($key_sym == SDLK_UP) {
                if (!$ch->jumping) {
                    $ch->reset_velocity;
                    $ch->jumping(1);
                    $ch->jump_dt($time);
                }
            }
        } elsif ($e->type == SDL_KEYUP) {
            my $key_sym = $e->key_sym;
            if (($key_sym == SDLK_RIGHT && $ch->step_x == 1) || ($key_sym == SDLK_LEFT && $ch->step_x == -1)) {
                $ch->step_x(0);
            }
        }
    }

    my $frames_cnt = 0;
    my $start_ticks = SDL::get_ticks();
    my $new_time = Time::HiRes::time;

    if ($new_time - $time > 0.02) {
        $display_surface->draw_rect($screen_rect, $bg_fill_color);

        my ($ch_pos_x, $ch_pos_y) = @{$ch->pos}[0..1];

        my $map_offset_x = do {
            if ($ch_pos_x < $screen_w/2 || $screen_w >= $max_x) {
                0;
            } elsif ($ch_pos_x - $screen_w/2 > $max_x - $screen_w) {
                $max_x - $screen_w;
            } else {
                $ch_pos_x - $screen_w/2;
            }
        };

        my $map_offset_y = do {
            if ($ch_pos_y < $screen_h/2) {
                0;
            } elsif ($ch_pos_y > $max_y - $screen_h/2) {
                $max_y - $screen_h;
            } else {
                $ch_pos_y - $screen_h/2;
            }
        };

        my ($len, $x) = (0, 0);

        #draw sky
        if ($map_offset_y < $sky_surface->h + $screen_h) {

            my $offs = do {
                if ($map_offset_y < $sky_surface->h) {
                    0;
                } else {
                    $map_offset_y - $sky_surface->h;
                }
            };

            my $sky_offset = $map_offset_x / 5;
            my $sky_surface_h = $sky_surface->h;
            $len = $x = 0;

            while ($len < $screen_w) {
                my $cur_len = $sky_surface->w - $sky_offset;
                $cur_len = $screen_w-$x unless $x+$cur_len <= $screen_w;
                $display_surface->blit_by($sky_surface, [$sky_offset, $offs, $cur_len, $sky_surface_h-$offs], [$x, 0, $cur_len, $sky_surface_h-$offs]);

                $sky_offset = 0;
                $len += $cur_len;
                $x += $cur_len;
            }
        }

        #draw trees
        if ($map_offset_y + $screen_h >= $max_y - $trees_surface->h) {

            my $trees_h = int($max_y - ($map_offset_y + $screen_h));
            my $trees_offset = $map_offset_x;
            my $trees_offset_h = $trees_surface->h-$trees_h;
            $len = $x = 0;

            while ($len < $screen_w) {
                my $cur_len = $trees_surface->w - $trees_offset;
                $cur_len = $screen_w-$x unless $x+$cur_len <= $screen_w;
                $display_surface->blit_by($trees_surface, [$trees_offset, 0, $cur_len, $trees_offset_h], [$x, $screen_h-$trees_surface->h+$trees_h, $cur_len, $trees_offset_h]);
                $trees_offset = 0;
                $len += $cur_len;
                $x += $cur_len;
            }
        }

        #draw mountains
        if ($map_offset_y + $screen_h >= $max_y - $trees_surface->h - $mountains_surface->h) {

            my $offs = do {
                if ($map_offset_y+$screen_h >= $max_y) {
                    $screen_h-$trees_surface->h-$mountains_surface->h;
                } elsif ($map_offset_y+$screen_h >= $max_y-$trees_surface->h) {
                    $screen_h - ($map_offset_y+$screen_h - ($max_y-($mountains_surface->h+$trees_surface->h)));
                } else {
                    $screen_h - ($mountains_surface->h - ($max_y - ($map_offset_y+$screen_h)));
                }
            };

            my $mountains_offset = $map_offset_x + ($map_offset_x/24);
            my $mountains_surface_h = $mountains_surface->h;
            $len = $x = 0;

            while ($len < $screen_w) {
                my $cur_len = $mountains_surface->w - $mountains_offset;
                $cur_len = $screen_w-$x unless $x+$cur_len <= $screen_w;
                $display_surface->blit_by($mountains_surface, [$mountains_offset, 0, $cur_len, $mountains_surface_h], [$x, $offs, $cur_len, $mountains_surface_h]);
                $mountains_offset = 0;
                $len += $cur_len;
                $x += $cur_len;
            }
        }

        $display_surface->blit_by(
            $whole_map_surface,
            [$map_offset_x, $map_offset_y, $screen_w, $screen_h],
            $screen_rect);

        $new_time = Time::HiRes::time;
        $ch->update_index($new_time);
        $ch->update_pos($new_time);

        #draw animated tiles
        my $start_x = int($map_offset_x/32);
        my $start_y = int($map_offset_y/32);

        foreach my $k (@animated_sprites_keys) {
            my $x = $k % $x_per_row;

             if ($x >= $start_x && $x <= $start_x + $x_per_screen+32) {
                my $y = ($k-$x)/$x_per_row;
                if ($y_per_row-$y >= $start_y && $y_per_row-$y <= $start_y+$y_per_screen+32) {
                    my $sprite = $map_animated_sprites{$k};
                    $sprite->update_index($new_time);
                    $sprite->draw($display_surface, [32*$x-$map_offset_x, $max_y-32*($y+1)-$map_offset_y, 32, 32]);
                }
            }
        }

        $ch->draw($display_surface);

        my $diff = SDL::get_ticks() - $start_ticks;
        if ($FRAME_RATE > $diff) {
            SDL::delay(int($FRAME_RATE-$diff));
        }

        $time = $new_time;
        if ($diff > 0) {
            if ($new_time - $aux_time > 5) {
                $FPS = int((++$frames_cnt/$diff)*1000);
                $aux_time = $new_time;
            }
        }

        $text_obj->write_to($display_surface, "FPS: $FPS");

        $display_surface->update;
    }
}

sub create_map {
    my %result;
    foreach my $x (0..(1024*3/32)-1) {
        foreach my $y (0..(768*3/32)-1) {
            if ($y == 0 || $y == 4 && $x != 3 || $y == 2 && $x !=4 || $y == 19 && $x != 4) {
                $result{$x+$y*(1024*3/32)} = 1;
            }
        }
    }

    $result{96*5+1} = 1;
    $result{96*5+7} = 1;
    delete $result{96*2+4};

    return (\%result, (1024*3, 768*3));
}

sub create_animated_sprites_map {
    my %result;
    $result{0} = AnimatedSprite->new(sprites_count => 11);
    $result{96+64} = AnimatedSprite->new(sprites_count => 11);
    $result{96+65} = AnimatedSprite->new(sprites_count => 11);
    #$result{10} = AnimatedSprite->new(sprites_count => 11);
    $result{96*24+32} = AnimatedSprite->new(sprites_count => 11);
    #$result{96*22+60} = AnimatedSprite->new(sprites_count => 11);
    #$result{96*28} = AnimatedSprite->new(sprites_count => 11);
    return \%result;
}
