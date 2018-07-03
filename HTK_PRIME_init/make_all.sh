########################
# EXTERNAL DATA 
MLFILE=/cygdrive/f/mlf_all/masterfile.mlf; 	#MLF file with word level transcriptions
FEATFOLDER=/cygdrive/f/features_DAZE;		#folder with features files
########################

## clean generated folders
rm -r -f lang scp mlf;
mkdir lang scp mlf;

########################
## PREPARE DATA

#prepare most of the files : transcriptions, list of phones, dictionaries
# mlf file as the input parameter
bash start/prep_files.sh $MLFILE;

#prepare filelists - folder with features as the input paramater
bash start/make_filelists.sh $FEATFOLDER

#prepare various language models
bash start/make_lm.sh

########################
## TRAIN

# train a model on a small random test dataset (TEST)
bash make_test.sh

#train a set of models on the whole dataset (MODELS)
#bash make_main.sh