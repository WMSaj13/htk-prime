################################
# prepare filelists

FEATFOLDER=$1; #FOLDER WITH FEATURES FILES

################################
# set enviroment variables
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8

# write global log
echo "* `date` : "  $0 $1  >> LOG_GLOBAL.txt

################################

#create list of all features files
find $FEATFOLDER -name '*.mfc' > scp/all_files.scp

#create random sets of files
shuf -n 3 scp/all_files.scp > scp/test3files.scp
shuf -n 10 scp/all_files.scp > scp/test10files.scp
shuf -n 30 scp/all_files.scp > scp/test30files.scp
shuf -n 100 scp/all_files.scp > scp/test100files.scp


#create small (better than not at all-) balanced filelists (includes examples of all monophones and extra files for rare ones)
bash -x start/create_balanced_train.sh 200 scp/all_files.scp mlf/phones1.mlf lang/monophones1 > scp/balanced200plus.scp



