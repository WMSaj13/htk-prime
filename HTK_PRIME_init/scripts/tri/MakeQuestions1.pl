#!/usr/bin/perl
#
use strict;

if (@ARGV <1)
{
    print "$0 <monophones0>\n"; 
    exit(1);
}

my $space = "   ";

my $monophones;
($monophones)= @ARGV;

open(IN, $monophones) or die;
my $line;
my @phoneme;
while($line = <IN>)
{
	chomp($line);
	push(@phoneme,$line);
}

close(IN);

my $indx;
for($indx=0;$indx<@phoneme;$indx++)
{
	print 'QS "L_'.$phoneme[$indx].'"'.$space.'{'.$phoneme[$indx].'-*}'."\n";
}
print "\n\n";
for($indx=0;$indx<@phoneme;$indx++)
{
	print 'QS "R_'.$phoneme[$indx].'"'.$space.'{*+'.$phoneme[$indx].'}'."\n";
}