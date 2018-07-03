#!/usr/bin/perl

use strict;

if ( @ARGV < 1 )
{
    print "$0 <vFloors>\n"; 
    exit(1);
}

my $vfloors;

($vfloors) = @ARGV;

my $line;
print "~o <MFCC_0_D_A_Z> <VecSize> 39\n";
open(IN, $vfloors);
while ($line = <IN>) 
{
	print $line;
}
close IN;

