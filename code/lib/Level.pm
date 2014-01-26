package Level;

use strict;
use warnings;
use 5.010;

use Mouse;
use SDL::Video;
use Character;
use AnimatedSprite;
use RidingBlock;
use BadGuy;
use Camera;
use TextureManager;
use LevelData;
use CollisionDetector;
use Loop::Constants;
use ParticleBase;
use ParticlesChunkBloodSplatters;
use ParticlesChunkCircles;
use ParticlesChunkBoom;

has filepath => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has level_data => (
    is => 'ro',
    isa => 'LevelData',
    init_arg => undef,
    lazy => 1,
    builder => '_build_level_data',
    handles => {
        ch => 'ch',
        w => 'w',
        h => 'h',
        animated_sprites => 'animated_sprites',
        blocks => 'blocks',
        riding_blocks => 'riding_blocks',
        bad_guys => 'bad_guys'
    }
);

has collision_detector => (
    is => 'ro',
    isa => 'CollisionDetector',
    writer => '_set_collision_detector'

);

has whole_map_surface => (
    is => 'ro',
    isa => 'SDL::Surface',
    writer => '_set_whole_map_surface'
);

has display_surface => (
    is => 'ro',
    isa => 'SDL::Surface',
    required => 1
);

has ['screen_w', 'screen_h'] => (
    is => 'ro',
    isa => 'Int'
);

has screen_rect => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    writer => '_set_screen_rect'
);

has bg_fill_color => (
    is => 'ro',
    isa => 'SDL::Color',
    writer => '_set_bg_fill_color'
);

has particles_chunks_list => (
    is => 'rw',
    isa => 'ArrayRef[ParticlesChunkBase]',
    default => sub { [] }
);

sub draw {
    my ($self, $camera) = @_;

    $self->display_surface->draw_rect($self->screen_rect, $self->bg_fill_color);
    my ($map_offset_x, $map_offset_y) = (int($camera->calc_x), int($camera->calc_y));

    #draw level blocks
    $self->display_surface->blit_by(
        $self->whole_map_surface,
        [$map_offset_x, $map_offset_y, $self->screen_w, $self->screen_h],
        $self->screen_rect);

    #draw animated tiles
    my $start_x = int($map_offset_x/$SPRITE_W);
    my $start_y = int($map_offset_y/$SPRITE_H);

    state $x_per_row = int($self->w/$SPRITE_W);
    state $y_per_row = int($self->h/$SPRITE_H);
    state $x_per_screen = int($self->screen_w/$SPRITE_W);
    state $y_per_screen = int($self->screen_h/$SPRITE_H);

    foreach my $k (keys %{$self->animated_sprites}) {
        my $x = $k % $x_per_row;
        if ($x >= $start_x && $x <= $start_x+$x_per_screen+$SPRITE_W) {
            my $y = ($k-$x)/$x_per_row;
            if ($y_per_row-$y >= $start_y && $y_per_row-$y <= $start_y+$y_per_screen+$SPRITE_H) {
                my $sprite = $self->animated_sprites->{$k};
                $sprite->draw($self->display_surface, [$SPRITE_W*$x-$map_offset_x, $self->h-$SPRITE_H*($y+1)-$map_offset_y, $SPRITE_W, $SPRITE_H]);
            }
        }
    }

    foreach my $riding_block (grep {
            $_->x >= $map_offset_x-$SPRITE_W && $_->x <= $map_offset_x + $self->screen_w+$SPRITE_W &&
            $_->y >= $map_offset_y-$SPRITE_H && $_->y <= $map_offset_y + $self->screen_h+$SPRITE_H
        } @{$self->riding_blocks}) {
        $riding_block->draw($self->display_surface, $map_offset_x, $map_offset_y);
    }

    foreach my $bad_guy (grep {
            $_->x >= $map_offset_x-$SPRITE_W && $_->x <= $map_offset_x + $self->screen_w+$SPRITE_W &&
            $_->y >= $map_offset_y-$SPRITE_H && $_->y <= $map_offset_y + $self->screen_h+$SPRITE_H
        } @{$self->bad_guys}) {
        $bad_guy->draw($self->display_surface, $map_offset_x, $map_offset_y);
    }

    state $screen_half_w = $self->screen_w/2;
    state $screen_half_h = $self->screen_h/2;

    my $map_x = do {
        if ($self->ch->x <= $screen_half_w) {
            $self->ch->x;
        } elsif ($self->ch->x <= $self->w - $screen_half_w) {
            $screen_half_w;
        } else {
            $screen_half_w + $self->ch->x - ($self->w - $screen_half_w);
        }
    };

    my $map_y = do {
        if ($self->ch->y <= $screen_half_h) {
            $self->ch->y;
        } elsif ($self->ch->y <= $self->h - $screen_half_h) {
            $screen_half_h;
        } else {
            $screen_half_h + $self->ch->y - ($self->h - $screen_half_h);
        }
    };

    #draw player
    $self->ch->draw($self->display_surface, int($map_x), int($map_y));

    #draw particles
    if (@{$self->particles_chunks_list}) {
        foreach (@{$self->particles_chunks_list}) {
            $_->draw($self->display_surface, $map_offset_x, $map_offset_y);
        }
    }
}

sub update {
    my ($self, $new_time) = @_;

    foreach (values %{$self->animated_sprites}) {
        $_->update_index($new_time);
    }

    foreach (@{$self->bad_guys}) {
        $_->update_index($new_time);
        $_->update_pos($new_time);
    }

    $self->ch->update_index($new_time);
    $self->ch->update_pos($new_time);
    foreach (@{$self->riding_blocks}) {
        $_->update_pos($new_time);
    }

    $self->collision_detector->resolve;

    if (@{$self->particles_chunks_list}) {
        my $i = 0;
        while ($i <= $#{$self->particles_chunks_list}) {
            my $particles_chunk = $self->particles_chunks_list->[$i];
            $particles_chunk->update($new_time);
            if ($particles_chunk->is_dead) {
                splice @{$self->particles_chunks_list}, $i, 1;
            } else {
                ++$i;
            }
        }
    }
}

sub handle_collision {
    my ($self) = @_;

    if ($self->collision_detector->is_bad_guy_val($self->ch->x-12, $self->ch->y-$SPRITE_HALF_H-1)) {
        $self->ch->handle_collision;

        my $particles_chunk = (int(rand(2)) == 1 ? ParticlesChunkBloodSplatters->new : ParticlesChunkCircles->new);
        $particles_chunk->init($self->ch->x, $self->ch->y, 2);
        push @{$self->particles_chunks_list}, $particles_chunk;
    }
}

sub make_boom {
    my ($self) = @_;

    my $cur_render_rect = $self->ch->cur_render_rect;
    my $size = 2;
    my @pos;
    for (my $x = 0; $x < $SPRITE_W; $x += $size) {
        for (my $y = 0; $y < $SPRITE_H; $y += $size) {
            push @pos, [$cur_render_rect->[0] + $x, $cur_render_rect->[1] + $y];
        }
    }

    my $particles_chunk = ParticlesChunkBoom->new(
        'x' => $self->ch->x, 
        'y' => $self->ch->y, 
        'img' => $self->ch->img,
        'size' => $size);
    $particles_chunk->init($self->ch->x, $self->ch->y, \@pos, $self->ch->img, $size);
    push @{$self->particles_chunks_list}, $particles_chunk;
}


sub init {
    my ($self) = @_;

    $self->_set_screen_rect([0, 0, $self->screen_w, $self->screen_h]);
    $self->_set_bg_fill_color(SDL::Color->new(241, 203, 144));

    my $whole_map_surface = SDLx::Surface->new(width => $self->w, height => $self->h, flags => SDL_ANYFORMAT & ~(SDL_SRCALPHA));
    croak(SDL::get_error) unless $whole_map_surface;
    croak(SDL::get_error) if SDL::Video::set_color_key($whole_map_surface, SDL_SRCCOLORKEY | SDL_RLEACCEL,  0);

    my $tiles_surface = TextureManager->instance->get('TILES');
    my $tile_rect = [0, 0, $SPRITE_W, $SPRITE_H];
    foreach my $x (0..($self->w/$SPRITE_W)-1) {
        foreach my $y (0..($self->h/$SPRITE_H)-1) {
            if (exists ${$self->blocks}{$y*$self->w/$SPRITE_W+$x}) {
                $whole_map_surface->blit_by($tiles_surface, $tile_rect, [$x*$SPRITE_W, $self->h-$SPRITE_H - $y*$SPRITE_H, $SPRITE_W, $SPRITE_H]);
            }
        }
    }

    $whole_map_surface = SDL::Video::display_format($whole_map_surface);
    croak(SDL::get_error) unless $whole_map_surface;
    croak(SDL::get_error) if SDL::Video::flip($whole_map_surface);
    #SDL::Video::save_BMP($whole_map_surface, "foo.bmp");

    $self->_set_whole_map_surface($whole_map_surface);

    $self->_set_collision_detector(CollisionDetector->new(
        level_data => $self->level_data
    ));
}

sub BUILD {
    my ($self) = @_;
    $self->init;
}

#TODO: implement
sub _build_level_data {
    my ($self) = @_;

    my $filepath = $self->filepath;

    ####do all dirty file-parsing work here and return the LevelData object

    #retrieve data and create a Character object:
    my $ch = Character->new(
        x => 300,
        y => 768*3+16-32*50, #some positions from the file
        w => 32,
        h => 32
    );

    #retrieve data about width and height of the level
    my $level_w = 1024*3;
    my $level_h = 768*3;

    #retrieve data about static blocks in the level
    my %blocks;
    foreach my $x (0..($level_w/$SPRITE_W)-1) {
        foreach my $y (0..($level_h/$SPRITE_H)-1) {
            if ($y == 0 || $y == 2 && $x !=4 || $y == 19 && $x != 4) {
                $blocks{$x+$y*($level_w/$SPRITE_W)} = 1;
            }
        }
    }

    $blocks{96+1} = 1;
    $blocks{96*3+3} = 1;
    $blocks{96*3+10} = 1;
    $blocks{96*33+1} = 1;
    $blocks{96*5+1} = 1;
    $blocks{96*5+7} = 1;
    $blocks{96*20 + 95} = 1;
    delete $blocks{96*2+4};
    delete $blocks{96*2+5};
    delete $blocks{96*19+39};

    #retrieve data about animated sprites in the level
    my %animated_sprites;

    $animated_sprites{96*20+21} = AnimatedSprite->new(sprites_count => 11, x => 10, y => 20, w => 32, h => 32);
    $animated_sprites{96+2} = AnimatedSprite->new(sprites_count => 11, x => 20, y => 30, w => 32, h => 32);

    #retrieve data about riding blocks in the level
    my @riding_blocks;

    #push @riding_blocks, RidingBlock->new(x => 32*10, y => 768*2+32*16, duration => 32*6, w => 32, h => 32, moving_type => $MOVEMENT->{DOWN});
    #push @riding_blocks, RidingBlock->new(x => 32*12, y => 768*2+32*16, duration => 32*3, w => 32, h => 32, moving_type => $MOVEMENT->{UP});
    #push @riding_blocks, RidingBlock->new(x => 32*11, y => 768*2+32*17, duration => 32*6, w => 32, h => 32, moving_type => $MOVEMENT->{DOWN});
    push @riding_blocks, RidingBlock->new(x => 96, y => 768*2+32*3, w => 32, h => 32, duration => 1000);

    push @riding_blocks, RidingBlock->new(x => 32*10, y => 768*2+32*14, duration => 32*7, w => 32, h => 32, moving_type => $MOVEMENT->{UP});
    push @riding_blocks, RidingBlock->new(x => 32*11, y => 768*2+32*14, duration => 32*7, w => 32, h => 32, moving_type => $MOVEMENT->{UP});

    #push @riding_blocks, RidingBlock->new(x => 96*2+50, y => 768*2+32*3+16, w => 32, h => 32, moving_type => $MOVEMENT->{RIGHT}, duration => 200);
    #push @riding_blocks, RidingBlock->new(x => 96*2+100, y => 768*2+32*3, w => 32, h => 32, moving_type => $MOVEMENT->{LEFT}, duration => 200);
    push @riding_blocks, RidingBlock->new(x => 64, y => 768+600, w => 32, h => 32, moving_type => $MOVEMENT->{RIGHT}, duration => 2000);

    my @bad_guys;
    for (1..5) {
        push @bad_guys, BadGuy->new(
            x => int(rand(1024)),
            y => 768*2+32*20+16,
            w => 32,
            h => 32,
            moving_type => (int(rand(2)) == 0 ? $MOVEMENT->{RIGHT} : $MOVEMENT->{LEFT}),
            duration => int(rand(500)) + 250
        );
    }

    #finally create and return LevelData object
    return LevelData->new(w => $level_w,
        h => $level_h,
        ch => $ch,
        blocks => \%blocks,
        animated_sprites => \%animated_sprites,
        riding_blocks => \@riding_blocks,
        bad_guys => \@bad_guys
    );
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1 ;
