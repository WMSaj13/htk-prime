#!/usr/bin/perl
# create a phonetic transcripton on text using a context of a letter
package main;
use File::Basename;
use strict;
use utf8;

binmode STDIN , ":utf8";
binmode STDOUT, ":utf8";


# check # of args 
if ( @ARGV != 1 )
{
    print "$0 <transcription : SAMPA or IMM >\n";	
    exit(1);
}

# get args
my $trans;
($trans) = @ARGV;

# set transcription
my $transcol;
if ($trans eq 'SAMPA') 
{
	$transcol=4;
}
else
{
	if ($trans eq 'IMM') {$transcol=5;}
	else {die 'transcription not recognized';}
}

 
#arrays
@main::transcript = ();
@main::context =();
@main::begcontext=(); #
@main::skip=();
@main::order = ();
@main::lencontext = (); 


#read transcrition data into arrays
my $dirname = dirname(__FILE__);
open FH,"<:encoding(UTF-8)",$dirname."/trans_rules.txt" or die;
my @data_raw_text=<FH>;
close FH;

my $line;
foreach $line(@data_raw_text)
{
	#fix the spaces
	$line=~ s/\n//g;
	#get definitions
	my @columns=split(/\t/,$line);
	push(@main::context,@columns[1]);
	push(@main::lencontext,length(@columns[1])); # length of context
	push(@main::begcontext,@columns[2]);
	push(@main::skip,@columns[3]);
	push(@main::transcript,@columns[$transcol]); #SAMPA 4 or IMM 5
	push(@main::order,@columns[6]); #order of transcription

}

#Transkrybowany tekst powinien zawierać słowa oddzielone 
# pojedynczymi spacjami (bez znaków interpunkcyjnych, bez podwójnych spacji).
# TO DO CHECK THE INTERPUNCTION IN TEXT THROW ERROR IF ANY

# read input file
my @input=<STDIN>;

foreach my $inTxt(@input)
{
chomp($inTxt);
if ($inTxt=~ m/\p{Punct}/) { die ('oops! : interpunction in the text'); }

#Na początku i na końcu tekstu umieszczamy po jednej spacji (w mailu używam <s> na oznaczenie spacji).
$main::inputText = " ".$inTxt." ";

#Indeksujemy znaki tekstu - pierwsza spacja tekstu otrzymuje indeks 0.
#(1) W tak przygotowanym tekście wyszukujemy wszystkie wystąpienia kontekstów wszystkich wzorców.

my $indx; #aux var for indexing

#pattern arrays
@main::pattern_at_pos = ();
my @last_pattern_len_at_pos = ();

# preparing pattern matched at
for($indx=0;$indx<length($main::inputText);$indx++)
{
	push(@main::pattern_at_pos,"-1");
	push(@last_pattern_len_at_pos,-1);
}

#pattern positions in text
my $prev_pos;
my $new_pos;
my $match_pos;

#iterare through contexts
for($indx=0;$indx<@main::context;$indx++)
{
	$prev_pos = -1;
	
	# find all contexts in texts 
	while(($new_pos=index($main::inputText,$main::context[$indx],$prev_pos+1))!=-1)
	{
		$prev_pos = $new_pos;
			
		#matching position
		$match_pos=$new_pos+$main::begcontext[$indx];

		#previous match length : -1 at the beg
		my $prev_match_len = $last_pattern_len_at_pos[$match_pos];
			
		#replace 'no match' and shorter match			
		if ($prev_match_len < $main::lencontext[$indx]) 
		{
			$main::pattern_at_pos[$match_pos] = $indx;
			$last_pattern_len_at_pos[$match_pos] = $main::lencontext[$indx];
			next;
		}
			
		#any following match is added to previously found
		if ($prev_match_len == $main::lencontext[$indx])
		{
			$main::pattern_at_pos[$match_pos] = $main::pattern_at_pos[$match_pos]." ".$indx;
		}
	}
}

	
#Dla każdego dopasowanego wzorca ustalamy miejsce dopasowania wzorca jako:
#"indeks pierwszego dopasowanego znaku" + "pozycja_startowa dopasowanego wzorca"
#"Miejsca dopasowania wzorców" przyjmują wartości ze zbioru (1, ... n).
#Na tym etapie w każdym miejscu dopasowania może być dopasowanych kilka wzorców.

# done in previous step

#Następnie dla każdego "miejsca dopasowania wzorca" zostawiamy tylko jeden dopasowany wzorzec z najdłuższym kontekstem (lenght(kontekst)).

# done in previous step

#Na koniec ustalamy ostateczną transkrypcję tekstu wybierając kolejne wzorce wj tak, aby:
#"miejsce dopasowania wzorca wj" = "miejsce dopasowania wzorca w(j-1)" + "liczba znaków wzorca w(j-1)"


#print "pozycja w tekście\tliterka\tdopasowane wzorce\tkolejnosc\n";
#my @array = split(//, $main::inputText);
#for($indx=0;$indx<length($main::inputText);$indx++)
#{
#	print $indx."\t".$array[$indx]."\n";
#}
#print "\n";

	
#############################
# GET TRANSCRIPTIONS
#@main::texttrans=();
#@main::sumorder=();
%main::data =();
	
#get transcriptions
get_trans(0,"","");
	
##################
	
#print transcriptions with associated sum of orders
#print "transkrypcja\tsuma\n";
foreach my $trans (sort {$main::data{$a} <=> $main::data{$b}} keys %main::data) 
{
	print $inTxt."\t".$trans."\n";
}

}

sub get_trans()
{
	my $curr_indx = shift;
	my $curr_sum_orders = shift;
	my $curr_trans = shift;
	
	
		
	if ($curr_indx<length($main::inputText))
	{	
		#gets all pattens that matches ...
		my @all_matched_patterns = split(/ /,$main::pattern_at_pos[$curr_indx]); 
		
		foreach my $pattern(@all_matched_patterns)
		{	
			# ... and follow
			my $newindx = $curr_indx + $main::skip[$pattern];
			my $newsum = $curr_sum_orders." ".$main::order[$pattern];
			my $newtrans = $curr_trans." ".$main::transcript[$pattern];
			get_trans($newindx,$newsum,$newtrans);					
		}
	}
	else
	{
			$main::data{$curr_trans} = join('',sort(split(/ /,$curr_sum_orders)));
	}
}
