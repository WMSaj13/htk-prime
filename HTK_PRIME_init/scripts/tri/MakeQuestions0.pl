#!/usr/bin/perl
#
use strict;

if (@ARGV <1)
{
    print "$0 <class descriptions>\n"; 
    exit(1);
}

my $space = "   ";

my $classes;
($classes)= @ARGV;

open(IN, $classes) or die;

my $line;
my $class;
my @phclass;

my $LEFT ="";
my $RIGHT ="";

while($line = <IN>)
{
	chomp($line);
	
	@phclass = split(/\t+/, $line);
	$class = shift(@phclass);
	@phclass = split(/\s/, @phclass[0]);
	
	
	$LEFT = $LEFT.'QS "L_'.$class.'"'.$space.'{';
	$RIGHT = $RIGHT.'QS "R_'.$class.'"'.$space.'{';
	
	my $phoneme;
	foreach $phoneme(@phclass)
	{
		$LEFT=$LEFT.$phoneme.'-*'.',';
		$RIGHT=$RIGHT.'*+'.$phoneme.',';
	}
	chop($LEFT);
	chop($RIGHT);
	$LEFT = $LEFT.'}'."\n";
	$RIGHT =$RIGHT.'}'."\n";
}
close(IN);

print $LEFT;
print "\n\n\n";
print $RIGHT;