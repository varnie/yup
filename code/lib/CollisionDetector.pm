package CollisionDetector;

use strict;
use warnings;
use 5.010;

use Mouse;
use base 'Class::Singleton';

use BadGuy;

has bad_guys_list => (
    is => 'ro',
    isa => 'ArrayRef[BadGuy]',
    default => sub { [] }
);

sub intersect {
    my ($this, $bounds) = @_;
    foreach my $bad_guy (@{$this->bad_guys_list}) {
        if ((abs($bounds->[0]-$bad_guy->pos->[0]) < 26)
        && (abs($bounds->[1]-$bad_guy->pos->[1]) < 24)) {
            return 1;
        }
    }
    return 0;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
