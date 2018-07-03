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
HVite -T 0 -t 1000.0 -H hmm15/macros -H hmm15/hmmdefs -S  $TESTSCP -l '*' -i hmm15/recout/recout_tied_models_$NAME.mlf -w lang/tied_$NAME.lat -p 0.0 -s 5.0 lang/dict_tied_$NAME tiedlist_$NAME 2>>LOG.txt 1>>LOG.txt;
HResults -s -I wintri_$NAME.mlf tiedlist_$NAME  hmm15/recout/recout_tied_models_$NAME.mlf >> hmm15/res.txt

