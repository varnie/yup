package ParticleBase;

use 5.010;
use strict;
use warnings;

use Mouse;

has ttl => (
    is => 'rw',
    isa => 'Num',
    default => 100
);

has red => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has green => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has blue => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

has pos => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub {[0, 0]}
);

has size => (
    is => 'rw',
    isa => 'Num',
    default => 6
);

sub draw {
    confess shift, " should have defined `update_index`";
}

sub update {
    confess shift, " should have defined `update_index`";
}

no Mouse;
__PACKAGE__->meta->make_immutable;
1;
