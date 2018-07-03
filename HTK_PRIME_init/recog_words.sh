###########################################
TOPDIR=$1;	#NAME OF DIRECTORY with config,lang,scp,mlf SUBDIRECTORIES
NAME=$2;	#NAME OF FOLDER
TESTSCP=$3;	#NAME OF TEST FILE SET

################################
# set enviroment variables
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8

# write global log
echo "* `date` : "  $0 $1 $2 $3 >> LOG_GLOBAL.txt

###########################################
#make main directory with model
cd $NAME;

#write log
echo "* `date` : "  $0 $1 $2 $3 >> LOG.txt

###########################################
# recognition
HVite -T 0 -t 1000.0 -H hmm15/macros -H hmm15/hmmdefs -S $TOPDIR/scp/$TESTSCP -l '*' -i hmm15/recout/recout_words_$NAME.$TESTSCP.mlf -w lang/bigram5k.lat -p 0.0 -s 5.0 lang/dict_lm tiedlist_$NAME 2>>LOG.txt 1>>LOG.txt;
bash $TOPDIR/scripts/fix_unicode.sh hmm15/recout/recout_words_$NAME.$TESTSCP.mlf > hmm15/recout/recout_words_fixed_$NAME.$TESTSCP.mlf
HResults -I $TOPDIR/mlf/masterfile.mlf tiedlist_$NAME hmm15/recout/recout_words_fixed_$NAME.$TESTSCP.mlf >> hmm15/res_lm_$TESTSCP.txt 

