#!/usr/bin/perl

use strict;
use warnings;

use SDL;
use SDL::Events;
use SDLx::App;
use SDLx::Surface;
use SDL::Image;
use SDL::Video;
use SDL::Surface;
use SDL::Rect;
use SDL::VideoInfo;
use SDL::PixelFormat;

use Time::HiRes;
use Carp qw/croak/;

use File::Basename;
use File::Spec::Functions qw/rel2abs/;

use FindBin;
use lib "$FindBin::Bin/lib";

use Character;
use 5.010;

SDL::init(SDL_INIT_VIDEO);

my $video_info = SDL::Video::get_video_info;
my ($screen_w, $screen_h, $bits_per_pixel) = ($video_info->current_w, $video_info->current_h, $video_info->vfmt->BitsPerPixel);

my $display = SDL::Video::set_video_mode($screen_w, $screen_h, $bits_per_pixel, SDL_HWSURFACE|SDL_DOUBLEBUF|SDL_FULLSCREEN);
my $display_surface = SDLx::Surface->new(surface => $display);
my $display_surface_ref = \$display_surface;

my $tiles_surface = SDLx::Surface->load(dirname(rel2abs($0)) . '/../tiles/JnRTiles.png');
croak(SDL::get_error) unless ($tiles_surface);

my $sky_surface = SDL::Image::load(dirname(rel2abs($0)) . '/../tiles/cloud.jpg');
croak(SDL::get_error) unless ($sky_surface);

my ($map_ref, $max_x) = create_map();
my %map = %$map_ref;

my $whole_map_surface = SDLx::Surface->new(width => $max_x, height => 768);
croak(SDL::get_error) unless ($whole_map_surface);
croak(SDL::get_error) if SDL::Video::set_color_key($whole_map_surface, SDL_SRCCOLORKEY, SDL::Video::map_RGB($whole_map_surface->format, 0, 0, 0));
croak(SDL::get_error) if SDL::Video::set_alpha($whole_map_surface, 0, 0);

my $tile_rect = [0, 0, 32, 32];
foreach my $x (0..$max_x/32) {
    my $val = $x*24; 
    foreach my $y (0 .. 24) {
        if (exists $map{$val + $y}) {  
            $tiles_surface->blit($whole_map_surface, $tile_rect, [$x*32, $y*32, 32, 32]);
        }
    }
}
$whole_map_surface->flip;
#SDL::Video::save_BMP($whole_map_surface->surface, "foo.bmp");

#say 'total ', scalar keys %map;
#say ((scalar keys %map) / 24); 
#test

my ($ch, $e, $quit, $time) = (
    Character->new(
        screen_w => $screen_w,
        screen_h => $screen_h, 
        map_width => $max_x, 
        map_ref => $map_ref, 
        jumping => 1, 
        velocity => 0
    ), 
    SDL::Event->new, 
    0, 
    Time::HiRes::time
);

my $FRAME_RATE = 1000/25;

while (!$quit) {
    SDL::Events::pump_events();
    while (SDL::Events::poll_event($e)) {
        my $key_sym;
        if ($e->type == SDL_KEYDOWN) {
            $key_sym = $e->key_sym;
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
                    $ch->dt($time);
                }
            }
        } elsif ($e->type == SDL_KEYUP) {
            $key_sym = $e->key_sym;
            if (($key_sym == SDLK_RIGHT && $ch->step_x == 1) || ($key_sym == SDLK_LEFT && $ch->step_x == -1)) {
                $ch->step_x(0);
            }
        }
    }
    
    my $frames_cnt = 0;
    my $start_ticks = SDL::get_ticks();
    my $new_time = Time::HiRes::time;
    my $bg_fill_color = SDL::Color->new(0x36, 0x9A, 0xD5);
    
    if ($new_time - $time > 0.01) {
        $display_surface->draw_rect([0, $sky_surface->h, $screen_w, $screen_h], $bg_fill_color);
        
        my $ch_pos_x = $ch->get_pos_x;     
        my $map_offset;
        my $sky_offset;
        my $foo;
        if ($ch_pos_x < $screen_w/2 || $screen_w >= $max_x) {
            $sky_offset = $map_offset = 0;
            $foo = 0;
        } elsif ($ch_pos_x - $screen_w/2 > $max_x - $screen_w) {
            $sky_offset = $max_x - $screen_w;
            $map_offset = $sky_offset / 32;
            $foo = $sky_offset;
        } else { 
            $sky_offset = $ch_pos_x - $screen_w/2;
            $map_offset = $sky_offset / 32;
            $foo = $sky_offset;
        }

        my ($len, $x) = (0, 0);
        while ($len < $screen_w) {
            my $cur_len = $sky_surface->w - $sky_offset;
            $cur_len = $screen_w-$x unless ($x+$cur_len <= $screen_w);
            $display_surface->blit_by($sky_surface, [$sky_offset, 0, $cur_len, $sky_surface->h], [$x, 0, $x+$cur_len, $sky_surface->h]);
            $sky_offset = 0;
            $len += $cur_len;
            $x += $cur_len;
        }
        
        my $tile_rect = [0, 0, 32, 32];
        my $y_offset = $screen_h - 768;
        $display_surface->blit_by(
            $whole_map_surface, 
            [$foo, 0, 1680, 768], 
            [0, $y_offset, 1680, 768]); 

        $new_time = Time::HiRes::time;
        $ch->update_index;
        $ch->update_pos($new_time);
        $ch->draw($display_surface_ref);
        
        $display_surface->update;

        my $diff = SDL::get_ticks() - $start_ticks;
        if ($FRAME_RATE > $diff) {
            SDL::delay($FRAME_RATE-$diff);
        }

        $time = $new_time;
        say "FPS: ", (++$frames_cnt/$diff)*1000;
    }
}

sub create_map {
    my %map; 
    foreach my $x (0..1024*3 -1) {
#       if ($x%24 == 23) {
        if (($x%24 != 22 && $x%24 != 21 && $x%24 != 18 && $x%24 != 17 && $x%24 != 17 && $x%24 != 16 && $x%24 != 16) && ($x == 23*4 || $x == 0 || $x == 23 || $x == 71 || $x == 58 || $x == 69 ||  $x == 84  || $x==119 || $x > 120 && $x != 769 && $x != 770)) {
            $map{$x} = 1;
        }
    }        
    $map{94} = 1;
    
    return (\%map, 1024*3);
}
