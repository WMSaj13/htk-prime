################################
#CREATE LIST OF FILES THAT INCLUDES EXAMPLES OF ALL MONOPHONES 

NFILES=$1; 	# number of initial rand files
MAINSCP=$2; 	# main scp file
MLFFILE=$3; 	# phones1 transcription
MONOLIST=$4; 	# monophones1 transcription

MAXADD=10;
MINMOD=10;

#create temp
mkdir -p start/temp;

#get random files
shuf -n $NFILES $MAINSCP > start/temp/random_files.scp

#get selected files labels and transcripions
sed 's/.*\/\(.*\)\.mfc/\1.lab/g' start/temp/random_files.scp > start/temp/labels.scp
HLEd -I $MLFFILE -i start/temp/labels.mlf /dev/null -S start/temp/labels.scp


#all models
sort $MONOLIST > start/temp/models_sorted.txt

#get models missing from transcriptions
grep -v '[\.#"]' start/temp/labels.mlf | sort | uniq > start/temp/models_in_trans.txt
comm start/temp/models_sorted.txt start/temp/models_in_trans.txt -23 > start/temp/missing_models.txt

#get rare models
grep -v '[\.#"]' start/temp/labels.mlf | sort | uniq -c | sort -k1 -n > start/temp/models_in_trans_count.txt
echo " $MINMOD position_marker" > start/temp/marker.txt

pos=`cat start/temp/marker.txt start/temp/models_in_trans_count.txt | sort -k1 -n | grep -n " $MINMOD position_marker" | sed 's/\(.*\):.*/\1/g'`

sort -k1 -n start/temp/models_in_trans_count.txt | head -n $((pos-1)) | sed 's/^[ ]*//g '| cut -f2 -d' ' | sort > start/temp/rare_models.txt;

#prepare list of files with missing and rare models
rm -f start/temp/add.scp start/temp/add2.scp

#prepare auxilary lookup of phones in transcriptions
grep -v '#' $MLFFILE | tr '\n' ' ' | sed 's/ \. / \.\n/g' > start/temp/lookup.txt

for MODEL in `cat start/temp/missing_models.txt`
do
	grep -e " $MODEL " start/temp/lookup.txt | sed 's/"\*\/\(.*\)\.lab".*/\1.mfc/g' | shuf -n $MAXADD | xargs -I % grep -e "%" $MAINSCP >> start/temp/add.scp
done

for MODEL in `cat start/temp/rare_models.txt`
do
	grep -e " $MODEL " start/temp/lookup.txt | sed 's/"\*\/\(.*\)\.lab".*/\1.mfc/g' | shuf -n $MAXADD | xargs -I % grep -e "%" $MAINSCP >> start/temp/add2.scp
done

#create joinded list of models
cat start/temp/random_files.scp start/temp/add.scp  start/temp/add2.scp | sort | uniq