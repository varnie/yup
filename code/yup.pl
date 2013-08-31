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

use 5.010;
use Time::HiRes;
use Carp qw/croak/;
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use FindBin;
use lib "$FindBin::Bin/lib";

use Character;

SDL::init(SDL_INIT_VIDEO);

my $video_info = SDL::Video::get_video_info;
my ($screen_w, $screen_h, $bits_per_pixel) = ($video_info->current_w, $video_info->current_h, $video_info->vfmt->BitsPerPixel);

my $display = SDL::Video::set_video_mode($screen_w, $screen_h, $bits_per_pixel, SDL_SWSURFACE|SDL_ANYFORMAT|SDL_FULLSCREEN);
my $display_surface = SDLx::Surface->new(surface => $display);
my $display_surface_ref = \$display_surface;

my $dir = dirname(rel2abs($0));

my $tiles_surface = SDLx::Surface->load("$dir/../tiles/JnRTiles.png");
croak(SDL::get_error) unless ($tiles_surface);

my $sky_surface = SDL::Image::load("$dir/../tiles/cloud_new1.png");
croak(SDL::get_error) unless ($sky_surface);
$sky_surface = SDL::Video::display_format($sky_surface);
croak(SDL::get_error) unless( $sky_surface);

my $trees_surface = SDL::Image::load("$dir/../tiles/forest_new.png");
croak(SDL::get_error) unless ($trees_surface);
$trees_surface = SDL::Video::display_format($trees_surface);
croak(SDL::get_error) unless( $trees_surface);

my $mountains_surface = SDL::Image::load("$dir/../tiles/mountains_new1.png");
croak(SDL::get_error) unless ($mountains_surface);

my $m_surface_new = SDLx::Surface->new(width => $mountains_surface->w, height => $mountains_surface->h, flags => SDL_ANYFORMAT & ~(SDL_SRCALPHA));
croak(SDL::get_error) unless ($m_surface_new);
croak(SDL::get_error) if SDL::Video::set_color_key($m_surface_new, SDL_SRCCOLORKEY | SDL_RLEACCEL, SDL::Video::map_RGB($m_surface_new->format, 0xf1, 0xcb, 0x86));
SDL::Video::blit_surface($mountains_surface, undef, $m_surface_new, undef);

$mountains_surface = SDL::Video::display_format($m_surface_new);
croak(SDL::get_error) unless( $mountains_surface);


my ($map_ref, $max_x) = create_map();
my %map = %$map_ref;

my $whole_map_surface = SDLx::Surface->new(width => $max_x, height => 768, flags => SDL_ANYFORMAT & ~(SDL_SRCALPHA));
croak(SDL::get_error) unless ($whole_map_surface);
croak(SDL::get_error) if SDL::Video::set_color_key($whole_map_surface, SDL_SRCCOLORKEY | SDL_RLEACCEL,  0);

my $tile_rect = [0, 0, 32, 32];
foreach my $x (0..$max_x/32) {
    my $val = $x*24;
    foreach my $y (0..24) {
        if (exists $map{$val + $y}) {
            $tiles_surface->blit($whole_map_surface, $tile_rect, [$x*32, $y*32, 32, 32]);
        }
    }
}
$whole_map_surface = SDL::Video::display_format($whole_map_surface);
croak(SDL::get_error) unless( $whole_map_surface);
undef $tiles_surface; #don't need it anymore

croak(SDL::get_error) if SDL::Video::flip($whole_map_surface);
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

my $FRAME_RATE = 1000/60;
my $bg_fill_color = SDL::Color->new(241, 203, 144);

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
                if (!$ch->jumping) { #:TODO: fix me
                    $ch->reset_velocity;
                    $ch->jumping(1);
                    $ch->jump_dt($time);
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

    if ($new_time - $time > 0.02) {
        $display_surface->draw_rect([0, $sky_surface->h, $screen_w, $screen_h], $bg_fill_color);

        my $ch_pos_x = $ch->get_pos_x;
        my $map_offset;
        if ($ch_pos_x < $screen_w/2 || $screen_w >= $max_x) {
            $map_offset = 0;
        } elsif ($ch_pos_x - $screen_w/2 > $max_x - $screen_w) {
            $map_offset = $max_x - $screen_w;
        } else {
            $map_offset = $ch_pos_x - $screen_w/2;
        }

        my $sky_offset = $map_offset / 5;
        my ($len, $x) = (0, 0);
        while ($len < $screen_w) {
            my $cur_len = $sky_surface->w - $sky_offset;
            $cur_len = $screen_w-$x unless ($x+$cur_len <= $screen_w);
            $display_surface->blit_by($sky_surface, [$sky_offset, 0, $cur_len, $sky_surface->h], [$x, 0, $cur_len, $sky_surface->h]);
            $sky_offset = 0;
            $len += $cur_len;
            $x += $cur_len;
        }

        my $trees_offset = $map_offset;
        $len = $x = 0;
        while ($len < $screen_w) {
            my $cur_len = $trees_surface->w - $trees_offset;
            $cur_len = $screen_w-$x unless ($x+$cur_len <= $screen_w);
            $display_surface->blit_by($trees_surface, [$trees_offset, 0, $cur_len, $trees_surface->h], [$x, $screen_h-$trees_surface->h, $cur_len, $trees_surface->h]);
            $trees_offset = 0;
            $len += $cur_len;
            $x += $cur_len;
        }

        my $mountains_offset = $map_offset + ($map_offset/24);
        $len = $x = 0;
        while ($len < $screen_w) {
            my $cur_len = $mountains_surface->w - $mountains_offset;
            $cur_len = $screen_w-$x unless ($x+$cur_len <= $screen_w);
            $display_surface->blit_by($mountains_surface, [$mountains_offset, 0, $cur_len, $mountains_surface->h], [$x, $screen_h-$trees_surface->h-$mountains_surface->h, $cur_len, $mountains_surface->h]);
            $mountains_offset = 0;
            $len += $cur_len;
            $x += $cur_len;
        }

        my $tile_rect = [0, 0, 32, 32];
        my $y_offset = $screen_h - 768;
        $display_surface->blit_by(
            $whole_map_surface,
            [$map_offset, 0, 1680, 768],
            [0, $y_offset, 1680, 768]);

        $new_time = Time::HiRes::time;
        $ch->update_index($new_time);
        $ch->update_pos($new_time);
        $ch->draw($display_surface_ref);

        #$display_surface->draw_rect([$ch->get_pos_x, $ch->get_pos_y, 31, 32], SDL::Video::map_RGB($m_surface_new->format, 0xFF, 0x00, 0x00));

        $display_surface->update;

        #my $diff = SDL::get_ticks() - $start_ticks;
        #if ($FRAME_RATE > $diff) {
        #    say "wait: ", $FRAME_RATE-$diff;
        #    SDL::delay($FRAME_RATE-$diff);
        #}

        $time = $new_time;
        #say "FPS: ", (++$frames_cnt/$diff)*1000;
    }
}

sub create_map {
    my %map;
    foreach my $x (0..1024*3 -1) {
        if ($x%24 == 23) {
        #if (($x%24 != 22 && $x%24 != 21 && $x%24 != 18 && $x%24 != 17 && $x%24 != 17 && $x%24 != 16 && $x%24 != 16) && ($x == 23*4 || $x == 0 || $x == 23 || $x == 71 || $x == 58 || $x == 69 ||  $x == 84  || $x==119 || $x > 120 && $x != 769 && $x != 770)) {
            $map{$x} = 1;
        }
    }
    $map{94} = 1;
    $map{10} = 1;
    return (\%map, 1024*3);
}
