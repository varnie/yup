package CollisionDetector;

use strict;
use warnings;
use 5.010;

use Mouse;
use base 'Class::Singleton';

use BadGuy;

use List::Util qw/max min/;

has bad_guys_list => (
    is => 'ro',
    isa => 'ArrayRef[BadGuy]',
    default => sub { [] }
);

has animated_sprites_list => (
    is => 'ro',
    isa => 'HashRef[AnimatedSprite]',
    default => sub{ [] }
);

has map_width => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

has map_height => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

sub simple_intersect {
    my ($this, $bounds) = @_;
    foreach my $bad_guy (@{$this->bad_guys_list}) {
        if ((abs($bounds->[0]-$bad_guy->pos->[0]) < 26)
        && (abs($bounds->[1]-$bad_guy->pos->[1]) < 24)) {
            return 1;
        }
    }
    return 0;
}

sub strict_intersect_bounds {
    my ($this, $bounds) = @_;

    state $x_per_row = int($this->map_width/32);

    my $max_y = $this->map_height;

    foreach my $k (%{$this->animated_sprites_list}) {
        my $x = $k % $x_per_row;
        my $y = ($k-$x)/$x_per_row;

        $x *= 32;
        $y = $max_y-32*($y+1);

        my ($bounds_x, $bounds_y) = @{$bounds}[0..1];

        if ((abs($bounds_x-$x) < 32) &&
            (abs($bounds_y-$y) < 32)) {

            my $max_l = max($bounds_x, $x);
            my $min_r = min($bounds_x+32, $x+32);

            my $max_t = max($bounds_y, $y);
            my $min_b = min($bounds_y+32, $y+32);

            my $width;
            #obj stands righter
            if ($bounds_x+32 > $x+32 && $bounds_x != int($bounds_x)) {
                $width = int($min_r-$max_l)+1;
            } else {
                $width = int($min_r-$max_l);
            }

            if ($bounds_y < $y && $bounds_y != int($bounds_y)) {
                $max_t = int($max_t)-1;
            }

            return [$max_l, $max_t, $width, int($min_b-$max_t)];
        }
    }

    return 0;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
