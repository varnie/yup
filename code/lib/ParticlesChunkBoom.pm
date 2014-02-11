package ParticlesChunkBoom;

use 5.010;
use strict;
use warnings;

use Mouse;
use ParticlesChunkBase;
use ParticleBoom;
use Inline with => 'SDL';

extends 'ParticlesChunkBase';

has img => (
    is => 'ro',
    isa => 'SDL::Surface',
    required => 1
);

has size => (
    is => 'rw',
    isa => 'Num',
    default => 6
);

has ['x', 'y'] => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

sub init {
    my ($self, $pos) = @_;

    #my $peaks_count = int(rand(4));
    #my $cur_peaks_count = 0;
    foreach my $pos (@{$pos}) {

        #my $is_peak = 0;
        #if ($cur_peaks_count < $peaks_count) {
        #    ++$cur_peaks_count;
        #    $is_peak = 1;
        #}

        my $is_fast = int(rand(10) > 3);
        my $vel_x = int(rand(8))*30;
        $vel_x -= 5 if $vel_x == 0;
        $vel_x *= -1 if rand(2) > 1;

        my $acc_x = 0;

        my $vel_y = ($is_fast ? - int(rand(40))*10 - 100: - int(rand(20))*10);
        my $acc_y = 350;

        push @{$self->items}, ParticleBoom->new(
            x => $self->x,
            y => $self->y - 16,
            src_pos => $pos,
            #vy => rand(16) - 32,
            #acc_y => rand(10) + ($is_peak ? 5 : 2),
            #coeff  => rand(2),
            #degrees => int(rand(120)) + 30, # [30, 120]
            is_fast => $is_fast,

            #
            newx => $self->x,
            newy => $self->y - 16,
            vel_x => $vel_x,
            vel_y => $vel_y,
            acc_x => $acc_x,
            acc_y => $acc_y
        );
    }
}

use Inline C => <<'END';
void draw(SV *self, SDL_Surface *dst, int map_offset_x, int map_offset_y, int screen_w, int screen_h) {

    const HV *obj_hash = SvRV(self);

    const AV *av_items = (AV *) SvRV(*hv_fetch(obj_hash, "items", 5, 0)); //5 is strlen("items")
    const int particles_count = av_top_index(av_items);

    if (particles_count >= 0) {
        const int size = SvIV(*hv_fetch(obj_hash, "size", 4, 0)); //4 is strlen("size")

        const SV *img_sv = *hv_fetch(obj_hash, "img", 3, 0); //3 is strlen("img")
        const void **pointers = (void**)(SvIV((SV*)SvRV(img_sv)));
        const SDL_Surface *src = (SDL_Surface*)(pointers[0]);

        const int src_width = src->w;
        const int dst_width = dst->w;
        const int max_dst_index = dst_width * dst->h;

        const int screen_max_x = map_offset_x + screen_w;
        const int screen_max_y = map_offset_y + screen_h;

        if (SDL_MUSTLOCK(src)) {
            SDL_LockSurface(src);
        }

        if (SDL_MUSTLOCK(dst)) {
            SDL_LockSurface(dst);
        }

        const int *src_pixels = (unsigned int *) src->pixels;
        int *dst_pixels = (unsigned int *) dst->pixels;

        int i;
        for (i = 0; i <= particles_count; ++i) {
            const HV *particle_obj_hash = SvRV(*av_fetch(av_items, i, 0));

            if (SvIV(*hv_fetch(particle_obj_hash, "ttl", 3, 0)) > 0) { //3 is strlen("ttl")
                //draw the particle

                //find position values
                const int x = SvIV(*hv_fetch(particle_obj_hash, "x", 1, 0)); //1 is strlen("x")
                const int y = SvIV(*hv_fetch(particle_obj_hash, "y", 1, 0)); //1 is strlen("y")

                if (x >= map_offset_x && x < screen_max_x && y > map_offset_y && y < screen_max_y) {

                    //find src_pos values
                    const AV *av_particle_src_pos = (AV *) SvRV(*hv_fetch(particle_obj_hash, "src_pos", 7, 0)); //7 is strlen("src_pos")

                    const int src_pos_x = SvIV(* av_fetch(av_particle_src_pos, 0, 0));
                    const int src_pos_y = SvIV(* av_fetch(av_particle_src_pos, 1, 0));

                    const int dst_x = x - map_offset_x;
                    const int dst_y = y - map_offset_y;

                    int i, j;
                    int src_offset = src_width*src_pos_y;
                    int dst_offset = dst_width*dst_y;

                    for (i = 0; i < size; ++i) { //iterate vertically

                        const int aux_dst_index = dst_offset + dst_x;
                        const int aux_src_index = src_offset + src_pos_x;

                        for (j = 0; j < size; ++j) { //iterate horizontally

                            const int dst_index = aux_dst_index + j;
                            if (dst_index > 0 && dst_index < max_dst_index) {
                                dst_pixels[dst_index] = src_pixels[aux_src_index + j];
                            }
                        }

                        src_offset += src_width;
                        dst_offset += dst_width;
                    }
                }
            }
        }

        if (SDL_MUSTLOCK(dst)) {
            SDL_UnlockSurface(dst);
        }

        if (SDL_MUSTLOCK(src)) {
            SDL_UnlockSurface(src);
        }
    }
}
END

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
