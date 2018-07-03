#!/usr/bin/perl
# create simple phoneme loop model

use strict;

if ( @ARGV < 2 )
{
    print "$0 <proto> <monophones0>\n"; 
    exit(1);
}

my $proto;
my $monophones;

($proto,$monophones) = @ARGV;

my $line;

my $protofile;
$protofile = "";
open(IN, $proto);
while ($line = <IN>) 
{
	$protofile=$protofile.$line;
}
close IN;

my @phonemes;
@phonemes = ();


open(IN, $monophones);
while ($line = <IN>) 
{
	chomp($line);
	push(@phonemes,$line);
}
close IN;

my $n;
my $i;
my $pos;
$n = @phonemes;
print substr($protofile,0,index($protofile,"~h \"proto\""));
$pos = index($protofile,"<BEGINHMM>");
for($i=0;$i<$n;$i++) 
{
	print "~h \"".@phonemes[$i]."\"\n";
	print substr($protofile,$pos,length($protofile)-$pos);
}
print "\n";
