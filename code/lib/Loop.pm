package Loop;

use strict;
use warnings;
use 5.010;

use Mouse;
use SDL;
use SDL::Events;
use SDL::Video;
use SDL::Surface;
use SDL::VideoInfo;
use SDL::PixelFormat;
use SDLx::App;
use SDLx::Surface;
use SDLx::Text;
use Level;
use File::Basename;
use File::Spec;
use Time::HiRes qw/time/;

has lvl => (
    is => 'rw',
    isa => 'Level',
    handles => {
        ch => 'ch'
    }
);

has 'screen_w' => (
    is => 'ro',
    isa => 'Int',
    writer => '_set_screen_w'
);

has 'screen_h' => (
    is => 'ro',
    isa => 'Int',
    writer => '_set_screen_h'
);

has display_surface => (
    is => 'ro',
    isa => 'SDL::Surface',
    writer => '_set_display_surface'
);

has camera => (
    is => 'ro',
    isa => 'Camera',
    writer => '_set_camera'
);

sub init {
    my ($self) = @_;

    SDL::init(SDL_INIT_VIDEO);

    my $video_info = SDL::Video::get_video_info;
    my ($screen_w, $screen_h, $bits_per_pixel) = ($video_info->current_w, $video_info->current_h, $video_info->vfmt->BitsPerPixel);
    $self->_set_screen_w($screen_w);
    $self->_set_screen_h($screen_h);

    $self->_set_display_surface(SDLx::Surface->new(
        surface => SDL::Video::set_video_mode($screen_w, $screen_h, $bits_per_pixel, SDL_SWSURFACE|SDL_ANYFORMAT#|SDL_FULLSCREEN
    )));

    $self->load_lvl;
}

sub run {
    my ($self) = @_;

    my @dirs = File::Spec->splitdir(File::Spec->rel2abs(__FILE__));
    @dirs = @dirs[0.. (scalar @dirs)-4];
    my $debug_text_obj = SDLx::Text->new(font => File::Spec->catfile(@dirs, 'fonts', 'FreeSerif.ttf'), x => 10, y => 40);

    my $quit = 0;
    my $e = SDL::Event->new;

    my $frames_cnt = 0;
    my $fps = 0;
    my $last_iteration_time = time;
    my $time_passed = $last_iteration_time;
    $self->ch->move_dt($time_passed);
    my $updates_cnt = 0;
    my $now;

    while (!$quit) {
        $now = time;
        $updates_cnt = 0;
        SDL::Events::pump_events();
        while (SDL::Events::poll_event($e)) {
            if ($e->type == SDL_KEYDOWN) {
                my $key_sym = $e->key_sym;
                if ($key_sym == SDLK_ESCAPE) {
                    $quit = 1;
                } elsif ($key_sym == SDLK_RIGHT) {
                    $self->ch->move_key_hold(1);
                    $self->ch->key_hold_start_time(time);
                    $self->ch->step_x(1);
                } elsif ($key_sym == SDLK_LEFT) {
                    $self->ch->move_key_hold(1);
                    $self->ch->key_hold_start_time(time);
                    $self->ch->step_x(-1);
                } elsif ($key_sym == SDLK_UP) {
                    if (!$self->ch->jumping) {
                        $self->ch->jumping(1);
                        $self->ch->vy($self->ch->max_vy);
                    }
                } elsif ($key_sym == SDLK_b) {
                    $self->lvl->make_boom;
                }
            } elsif ($e->type == SDL_KEYUP) {
                my $key_sym = $e->key_sym;
                if (($key_sym == SDLK_RIGHT && $self->ch->step_x == 1) || ($key_sym == SDLK_LEFT && $self->ch->step_x == -1)) {
                    $self->ch->move_key_hold(0);
                    $self->ch->step_x(0);
                }
            }
        }

        #say ($now - $last_iteration_time);
        if ($now - $last_iteration_time >= 0.0017) {
            while ($now - $last_iteration_time >= 0.0017) {
                $self->step($last_iteration_time + 0.0017);
                $last_iteration_time += 0.0017;
                ++$updates_cnt;
            }
        }

        $self->lvl->handle_collision;

        $last_iteration_time = $now;

        $self->lvl->draw($self->camera);
        $debug_text_obj->write_to($self->display_surface, "FPS: $fps Updates count: $updates_cnt: jumping: " . $self->ch->jumping );
        #$debug_text_obj->write_to($self->display_surface, "is_on_block: " . (defined $self->ch->riding_block ? 1 : 0));
        #$debug_text_obj->write_to($self->display_surface, "character x pos: " . $self->ch->x);
        $self->display_surface->flip;

        ++$frames_cnt;

        my $new_time = time;
        if ($new_time - $time_passed >= 1.0) {
            $fps = $frames_cnt;
            $frames_cnt = $updates_cnt = 0;
            $time_passed = $new_time;
        }
    }
}

sub step {
    my ($self, $new_time) = @_;

    $self->lvl->update($new_time);
    $self->camera->update;
}

sub load_lvl {
    my ($self) = @_;

    #TODO: use file configs instead
    $self->lvl(Level->new(
        screen_w => $self->screen_w,
        screen_h => $self->screen_h,
        filepath => 'lvl1',
        display_surface => $self->display_surface
    ));

    $self->_set_camera(Camera->new(screen_w => $self->screen_w,
        screen_h => $self->screen_h,
        map_width => $self->lvl->w,
        map_height => $self->lvl->h,
        sprite_2_follow => $self->ch
    ));

    $self->camera->update;
};

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
