#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use FindBin;
use lib "$FindBin::Bin/lib";
use Loop;

my $game = Loop->new;
$game->init;
$game->run;
