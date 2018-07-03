###########################################
TOPDIR=$1;	#NAME OF DIRECTORY with config,lang,scp,mlf SUBDIRECTORIES
FOLDER=$2;	#NAME OF LOCAL DIRECTORY
NAME=$3;	#NAME OF ORGINAL MODEL
TESTSCP=$4;	#NAME OF TEST FILE SET

################################
# set enviroment variables
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8

# write global log
echo "* `date` : "  $0 $1 $2 $3 $4  >> LOG_GLOBAL.txt

###########################################
#make main directory with model
cd $FOLDER;

#write log
echo "* `date` : "  $0 $1 $2 $3 $4  >> LOG.txt
    

###################
MIX=2; # first split
OLD=15; # start model
$OLD=$NEW;$NEW=$(($OLD+1)); #

# max split 16
for((;MIX<=16;MIX=$(($MIX*2))))
do
	# prepare HHed command
	echo -e "MU $MIX {*.state[2-4].mix}" > mix$MIX.hed
	
	NEW=$(($OLD+1));
	mkdir -p hmm$NEW
	HHEd -T 1 -H hmm$OLD/hmmdefs -M hmm$NEW mix$MIX.hed tiedlist_$NAME 2>>LOG.txt 1>>LOG.txt;
	cp hmm$OLD/macros hmm$NEW/
	OLD=$NEW;NEW=$(($OLD+1));
	
	# train mix twice
	for((M=1; M <= 2 ; M=$(($M+1))))
	do
		mkdir -p hmm$NEW
		HERest -A -D -T 0 -B -m 0 -C config_HERest -I wintri_$NAME.mlf -t 250.0 150.0 1000.0 -s stats -S aligned_files_$NAME.scp -H hmm$OLD/macros -H hmm$OLD/hmmdefs -M hmm$NEW tiedlist_$NAME 2>>LOG.txt 1>>LOG.txt;
		
		mkdir -p hmm$NEW/recout
		HVite -T 1 -H hmm$NEW/macros -H hmm$NEW/hmmdefs -S  $TOPDIR/scp/$TESTSCP -l '*' -i hmm$NEW/recout/recout_tied_models_$NAME.mlf -w lang/tied_$NAME.lat -p 0.0 -s 5.0 lang/dict_tied_$NAME tiedlist_$NAME 2>>LOG.txt 1>>LOG.txt;
		HResults -s -I wintri_test_$NAME.mlf tiedlist_$NAME  hmm$NEW/recout/recout_tied_models_$NAME.mlf >> hmm$NEW/res.txt;
		
		OLD=$NEW;NEW=$(($OLD+1));
	done
	# test resulst
done
