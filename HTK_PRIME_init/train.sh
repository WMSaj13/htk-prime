###########################################
TOPDIR=$1;	#NAME OF DIRECTORY with config,lang,scp,mlf SUBDIRECTORIES
NAME=$2;	#NAME OF FOLDER
FILESCP=$3;	#NAME OF TRAINING FILE SET
TESTSCP=$4;	#NAME OF TEST FILE SET

################################
# set enviroment variables
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8

# write global log
echo "* `date` : "  $0 $1 $2 $3 $4  >> LOG_GLOBAL.txt

###########################################
#make main directory with model
rm -r -f $NAME;
mkdir $NAME;
cd $NAME;

#write log
echo "* `date` : "  $0 $1 $2 $3 $4  >> LOG.txt

###########################################
#copy files from TOPDIR

cp $TOPDIR/lang/monophones* ./
cp $TOPDIR/config/config_* ./

mkdir lang
cp $TOPDIR/lang/* lang/

# make a test subset of transcriptions
sed 's/.*\/\([^\/]*\.\)mfc/*\/\1lab/g'  $TOPDIR/scp/$TESTSCP > test_mlfs.scp;
HLEd -I $TOPDIR/mlf/phones1.mlf -S test_mlfs.scp -i test_$NAME.temp.mlf /dev/null;
cat test_$NAME.temp.mlf | bash $TOPDIR/scripts/fix_unicode.sh > test_phones1_$NAME.mlf;
rm test_$NAME.temp.mlf;

###########################################
# MONOPHONES
###########################################

# ----------------------------------------------------------------------------
# HTKBook "3.2.1 Step 6 - Creating Flat Start Monophones" (p. 33)
#  "the command will create a new version of proto in the directory hmm0 in which the zero means and unit variances
#  above have been replaced by the global speech means and variances"
# ----------------------------------------------------------------------------

mkdir -p hmm0
HCompV -T 1 -C config_HCompV -f 0.01 -S $TOPDIR/scp/$FILESCP -m -M hmm0 $TOPDIR/config/proto  2>>LOG.txt  1>>LOG.txt;

# ----------------------------------------------------------------------------
# HTKBook "3.2.1 Step 6 - Creating Flat Start Monophones" (p. 33)
#  "Given this new prototype model stored
#  in the directory hmm0, a Master Macro File (MMF) called hmmdefs containing a copy for each of
#  the required monophone HMMs is constructed by manually copying the prototype and relabelling
#  it for each required monophone (including “sil”)."
# ----------------------------------------------------------------------------

#prepare hmmdef and macros
perl $TOPDIR/scripts/makeHMMdef.pl hmm0/proto monophones0 > hmm0/hmmdefs
perl $TOPDIR/scripts/makeMacro.pl hmm0/vFloors > hmm0/macros

# ----------------------------------------------------------------------------
# HTKBook "3.2.1 Step 6 - Creating Flat Start Monophones" (p. 34,35)
#  "The flat start monophones stored in the directory hmm0 are re-estimated (..)
#  Execution of HERest should be repeated twice more, changing the name of the
#  input and output directories (set with the options -H and -M) each time, 
#  until the directory hmm3 contains the final set of initialised monophone HMMs."
# ----------------------------------------------------------------------------

for((OLD = 0; OLD < 3 ; OLD=$(($OLD+1))))
do
	NEW=$(($OLD+1))
	mkdir -p hmm$NEW
	HERest -A -D -T 0 -C config_HERest -I $TOPDIR/mlf/phones0.mlf -t 250.0 150.0 1000.0 -s stats -S $TOPDIR/scp/$FILESCP -H hmm$OLD/macros -H hmm$OLD/hmmdefs -M hmm$NEW monophones0  2>>LOG.txt 1>>LOG.txt;
done

###########################################
# test HTVite recognition

mkdir -p hmm3/recout
HVite -T 0 -H hmm3/macros -H hmm3/hmmdefs -S $TOPDIR/scp/$TESTSCP -l '*' -i hmm3/recout/recout_phones_$NAME.mlf -w lang/phones0.lat -p 0.0 -s 5.0 lang/phones0_dict monophones0 2>>LOG.txt 1>>LOG.txt;
HResults -I $TOPDIR/mlf/phones0.mlf monophones0 hmm3/recout/recout_phones_$NAME.mlf >> hmm3/res.txt

# ----------------------------------------------------------------------------
# HTKBook "3.2.2 Step 7 - Fixing the Silence Models" (p. 35)
# ----------------------------------------------------------------------------

mkdir -p hmm4

# ----------------------------------------------------------------------------
# HTKBook "3.2.2 Step 7 - Fixing the Silence Models" (p. 35)
#  "Use a text editor on the file hmm3/hmmdefs to copy the centre state of the sil model to make
#  a new sp model and store the resulting MMF hmmdefs, which includes the new sp model, in
#  the new directory hmm4."
# ----------------------------------------------------------------------------

#add
perl $TOPDIR/scripts/makesp hmm3/hmmdefs > hmm4/sil_def
cat hmm3/hmmdefs hmm4/sil_def > hmm4/hmmdefs
cp hmm3/macros hmm4/macros

# ----------------------------------------------------------------------------
# HTKBook "3.2.2 Step 7 - Fixing the Silence Models" (p. 35)
#  "Run the HMM editor HHEd to add the extra transitions required and tie the sp state to the
#  centre sil state"
# ----------------------------------------------------------------------------

#tie
mkdir -p hmm5
HHEd -H hmm4/macros -H hmm4/hmmdefs -M hmm5 $TOPDIR/config/sil.hed monophones1 2>>LOG.txt  1>>LOG.txt;

# ----------------------------------------------------------------------------
# HTKBook "3.2.2 Step 7 - Fixing the Silence Models" (p. 36)
# "Finally, another two passes of HERest are applied using the phone transcriptions with sp
# models between words. This leaves the set of monophone HMMs created so far in the directory
# hmm7"
# ----------------------------------------------------------------------------

# train again : monophones1
for((OLD = 5; OLD < 7 ; OLD=$(($OLD+1))))
do
	NEW=$(($OLD+1))
	mkdir -p hmm$NEW
	HERest -A -D -T 0 -C config_HERest -I $TOPDIR/mlf/phones1.mlf -t 250.0 150.0 1000.0 -s stats -S $TOPDIR/scp/$FILESCP -H hmm$OLD/macros -H hmm$OLD/hmmdefs -M hmm$NEW monophones1  2>>LOG.txt 1>>LOG.txt;
done

###########################################
# test HTVite recognition

mkdir -p hmm7/recout
HVite -T 0 -H hmm7/macros -H hmm7/hmmdefs -S $TOPDIR/scp/$TESTSCP -l '*' -i hmm7/recout/recout_phones_$NAME.mlf -w lang/phones1.lat -p 0.0 -s 5.0 lang/phones1_dict monophones1 2>>LOG.txt  1>>LOG.txt;
HResults -I $TOPDIR/mlf/phones1.mlf monophones1 hmm7/recout/recout_phones_$NAME.mlf >> hmm7/res.txt

# ----------------------------------------------------------------------------
# HTKBook "3.2.3 Step 8 - Realigning the Training Data" (p. 36)
#  "The phone models created so far can be used to realign the training data and create
#  new transcriptions. This can be done with a single invocation of the HTK recognition tool HVite(..)"
# ----------------------------------------------------------------------------

#make alignment
HVite -T 0 -a -o S -m -p -10 -b sil -C config_HVite -H hmm7/macros -H hmm7/hmmdefs -S $TOPDIR/scp/$FILESCP -l '*' -y lab -i aligned_$NAME.mlf -I $TOPDIR/mlf/masterfile.mlf $TOPDIR/lang/dict_sp_nosp monophones1 2>>LOG.txt 1>>LOG.txt;

#additional step -2 : a rare error fix : sometimes for unknown reason (HTK bug?) aligned transcriptions lacks the ending 'sil'
# and if aligned pronouncuation ends with 'sp' generates  'ERROR [+7332]  CreateInsts: Cannot have Tee models at start or end of transcription'

egrep ' sil sil| sp$|"|\.'  aligned_$NAME.mlf | sed 's/[0-9]* [0-9]* //g' | tr '\n' ' ' | sed 's/"[^\"]*lab" [^\.]* sil \. //g' | sed 's/"\*\/\([^\"]*\)lab" [^\.]* \./\1mfc\n/g' | tr ' ' '\n' | sed '/^$/d' | sort > ALIGNMENT_files_excluded_aligned_sp_at_end_$MODEL.txt

#additional step -1 : check if all files were aligned
grep -e "*" aligned_$NAME.mlf | sed 's/".*\/\(.*\)"/\1/g' | sed 's/\.lab/\.mfc/g' | sort > ALIGNMENT_all_files_aligned_$MODEL.txt

# final list : all aligned files minus files aligned with errors
comm -23 ALIGNMENT_all_files_aligned_$MODEL.txt ALIGNMENT_files_excluded_aligned_sp_at_end_$MODEL.txt | xargs -I % grep -e "/%$" $TOPDIR/scp/$FILESCP > aligned_files_$NAME.scp
# ----------------------------------------------------------------------------
# HTKBook "3.2.3 Step 8 - Realigning the Training Data" (p. 37)
#  "Once the new phone alignments have been created, another 2 passes of HERest can be applied
#  to reestimate the HMM set parameters again. Assuming that this is done, the final monophone
#  HMM set will be stored in directory hmm9."
# ----------------------------------------------------------------------------

# train again : aligned monophones1
for((OLD = 7; OLD < 9 ; OLD=$(($OLD+1))))
do
	NEW=$(($OLD+1))
	mkdir -p hmm$NEW
	HERest -A -D -T 0 -C config_HERest -I aligned_$NAME.mlf -t 250.0 150.0 1000.0 -s stats -S aligned_files_$NAME.scp -H hmm$OLD/macros -H hmm$OLD/hmmdefs -M hmm$NEW monophones1  2>>LOG.txt 1>>LOG.txt;
done

###########################################
# test HTVite recognition

mkdir -p hmm9/recout

#phones recog
HVite -T 0 -H hmm9/macros -H hmm9/hmmdefs -S $TOPDIR/scp/$TESTSCP -l '*' -i hmm9/recout/recout_phones_$NAME.mlf -w lang/phones1.lat -p 0.0 -s 5.0 lang/phones1_dict monophones1 2>>LOG.txt  1>>LOG.txt;
HResults -I $TOPDIR/mlf/phones1.mlf monophones1 hmm9/recout/recout_phones_$NAME.mlf >> hmm9/res.txt

#words recog
#HVite -T 0 -H hmm9/macros -H hmm9/hmmdefs -S $TOPDIR/scp/$TESTSCP -l '*' -i hmm9/recout/recout_words_$NAME.mlf -w lang/bigram5k.lat -p 0.0 -s 5.0 lang/dict_lm monophones1 2>>LOG.txt  1>>LOG.txt;
#bash $TOPDIR/scripts/fix_unicode.sh hmm9/recout/recout_words_$NAME.mlf > hmm9/recout/recout_words_fixed_$NAME.mlf
#HResults -I $TOPDIR/mlf/masterfile.mlf monophones1 hmm9/recout/recout_words_fixed_$NAME.mlf >> hmm9/res.txt

###########################################
# TRIPHONES
###########################################

# ----------------------------------------------------------------------------
# HTKBook "3.3.1 Step 9 - Making Triphones from Monophones" (p. 38)
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# HTKBook "3.3.1 Step 9 - Making Triphones from Monophones" (p. 38)
#  "That is, executing
#  HLEd -n triphones1 -l '*' -i wintri.mlf mktri.led aligned.mlf
#  will convert the monophone transcriptions in aligned.mlf to an equivalent set of triphone transcriptions
#  in wintri.mlf."
# ----------------------------------------------------------------------------

#prepare mktri.led script
#word internal triphones
echo "WB sp" > mktri.led # sp is word boundary # exclude this line for cross word triphones
echo "WB sil" >> mktri.led # sil is word boundary
echo "TC" >> mktri.led # convert to triphones

#prepare triphones list and transcriptions
HLEd -n triphones1_$NAME -l '*' -i wintri_$NAME.mlf mktri.led aligned_$NAME.mlf 2>>LOG.txt 1>>LOG.txt;

#prepare triphones of test set - may contains different set of triphones
HLEd -l '*' -i wintri_test_$NAME.mlf mktri.led test_phones1_$NAME.mlf 2>>LOG.txt 1>>LOG.txt;

# ----------------------------------------------------------------------------
# HTKBook "3.3.1 Step 9 - Making Triphones from Monophones" (p. 38)
#  "The cloning of models can be done efficiently using the HMM editor HHEd (...)
#  the edit script mktri.hed contains a clone command CL followed by TI commands to tie all
#  of the transition matrices in each triphone set (...)"
# ----------------------------------------------------------------------------

#prepare mktri.hed
perl $TOPDIR/scripts/tri/maketrihed monophones1 triphones1_$NAME > mktri.hed

#monophones models in hmm9 to triphone models in hmm10
mkdir -p hmm10;
HHEd -B -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1 2>>LOG.txt  1>>LOG.txt;


# ----------------------------------------------------------------------------
# HTKBook "3.3.1 Step 9 - Making Triphones from Monophones" (p. 40)
#  "Re-estimation should be again
#  done twice, so that the resultant model sets will ultimately be saved in hmm12"
# ----------------------------------------------------------------------------

# train again : wintri triphones1 (save in binary format -B)
for((OLD = 10; OLD < 12 ; OLD=$(($OLD+1))))
do
	NEW=$(($OLD+1))
	mkdir -p hmm$NEW
	HERest -A -D -T 0 -B -C config_HERest -I wintri_$NAME.mlf -t 250.0 150.0 1000.0 -s stats -S aligned_files_$NAME.scp -H hmm$OLD/macros -H hmm$OLD/hmmdefs -M hmm$NEW triphones1_$NAME  2>>LOG.txt 1>>LOG.txt;
done

###########################################
# TIED STATE TRIPHONES
###########################################

# ----------------------------------------------------------------------------
# HTKBook "3.3.2 Step 10 - Making Tied-State Triphones (p. 40)
# ----------------------------------------------------------------------------

# preparing an extended triphone set in advance for being joined via AU command
# ----------------------------------------------------------------------------
# HTKBook "3.3.2 Step 10 - Making Tied-State Triphones (p. 42)
#  "The set of triphones used so far only includes those needed to cover the training data. The AU
#  command takes as its argument a new list of triphones expanded to include all those needed for
#  recognition. This list can be generated, for example, by using HDMan on the entire dictionary
#  (not just the training dictionary), converting it to triphones using the command TC and outputting
#  a list of the distinct triphones to a file using the option -n"
# ----------------------------------------------------------------------------

 ## prepare full list of triphones
 ## HTKBook 
 echo "TC" > maketri.ded
 HDMan -T 1 -b sp -g maketri.ded -n fulllist_$NAME -l LOG_FULLTRI_$NAME.txt dict_tri_$NAME lang/dict_sp_nosp 2>>LOG.txt 1>>LOG.txt; # sp is word boundary (inter words triphones)
 ##HDMan -T 1 -g maketri.ded -n fulllist_$NAME -l LOG_FULLTRI_$NAME.txt  dict_tri_$NAME lang/dict_sp_nosp 2>>LOG.txt 1>>LOG.txt; # sp included in triphones(cross words triphones);

 ### corrections to HTKBook procedure
 sed 's/^[^ ]* //g' dict_tri_$NAME | tr ' ' '\n' | sed '/^$/d' | sort | uniq > fulllist_dict_$NAME;
 ## due to use of alignment procedure earlier we have some words without sp's between and triphones that from word-word contionous transcriptuon so:
 cat fulllist_dict_$NAME triphones1_$NAME | sort | uniq >  fulllist_$NAME;
 ## otherwise
 ## cat fulllist_dict_$NAME >  fulllist_$NAME;

# ----------------------------------------------------------------------------
# HTKBook "3.3.2 Step 10 - Making Tied-State Triphones (p. 41-43)
#  "The edit script tree.hed (...) contains the instructions regarding which contexts to examine
#  for possible clustering (...)"
# ----------------------------------------------------------------------------

## prepare tree.hed
echo "RO 100 stats" >tree.hed;
echo "" >> tree.hed;
##prepare questions using clusters as described in tree_questions.txt
echo "TR 0" >>tree.hed
echo "" >> tree.hed;
perl $TOPDIR/scripts/tri/MakeQuestions0.pl $TOPDIR/scripts/tri/clusters/questions_SAMPA_8V2012.txt >> tree.hed
perl $TOPDIR/scripts/tri/MakeQuestions1.pl monophones0 >> tree.hed;
echo "TR 12" >>tree.hed;
perl $TOPDIR/scripts/tri/MakeClusteredTri.pl TB 350 monophones1 >> tree.hed;
##full list triphones etc
echo "TR 1" >>tree.hed
echo "AU \"fulllist_$NAME\"" >>tree.hed; # commented if no extra triphones are added
echo "CO \"tiedlist_$NAME\"" >>tree.hed;
echo "ST \"trees_$NAME\"" >>tree.hed;

# ----------------------------------------------------------------------------
# HTKBook "3.3.2 Step 10 - Making Tied-State Triphones (p. 40)
#  "Decision tree state tying is performed by running HHEd (...)"
# ----------------------------------------------------------------------------

#tie
mkdir -p hmm13
HHEd -B -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1_$NAME  2>>LOG.txt 1>>LOG.txt;

# ----------------------------------------------------------------------------
# HTKBook "3.3.2 Step 10 - Making Tied-State Triphones (p. 40)
#  "Finally, and for the last time, the models are re-estimated twice using HERest. Fig. 3.14
#  illustrates this last step in the HMM build process. The trained models are then contained in the
#  file hmm15/hmmdefs."
# ----------------------------------------------------------------------------

# train again : wintri tiedlist (save in binary format)
for((OLD = 13; OLD < 15 ; OLD=$(($OLD+1))))
do
	NEW=$(($OLD+1))
	mkdir -p hmm$NEW
	HERest -A -D -T 0 -B -m 0 -C config_HERest -I wintri_$NAME.mlf -t 250.0 150.0 1000.0 -s stats -S aligned_files_$NAME.scp -H hmm$OLD/macros -H hmm$OLD/hmmdefs -M hmm$NEW tiedlist_$NAME  2>>LOG.txt 1>>LOG.txt;
done

##############################################################################
# ----------------------------------------------------------------------------
# HTKBook "3.4.1 Step 11 - Recognising the Test Data (p. 43)
# ----------------------------------------------------------------------------

# test HTVite recognition

mkdir -p hmm15/recout

####################
# prepare a dictionary " triphone - triphone" for the recognition tests
tr ' ' '\n' < tiedlist_$NAME | sort | uniq > lang/tied_$NAME;
paste lang/tied_$NAME lang/tied_$NAME | sort  > lang/dict_tied_$NAME;

###################
echo '$words=' | tr -d '\n' > lang/tied_$NAME.net;
grep -v '^sil$' lang/tied_$NAME | grep -v '^sp$' | tr '\n' '|'  >> lang/tied_$NAME.net   # add all models separated by | apart from sil
echo "sil;">> lang/tied_$NAME.net  # add sil model and EOL
echo '([sil] <$words [sp]> [sil])' >> lang/tied_$NAME.net;
HParse lang/tied_$NAME.net lang/tied_$NAME.lat

####################
# recognition
HVite -T 0 -H hmm15/macros -H hmm15/hmmdefs -S  $TOPDIR/scp/$TESTSCP -l '*' -i hmm15/recout/recout_tied_models_$NAME.mlf -w lang/tied_$NAME.lat -p 0.0 -s 5.0 lang/dict_tied_$NAME tiedlist_$NAME 2>>LOG.txt 1>>LOG.txt;
# make 
HResults -s -I wintri_test_$NAME.mlf tiedlist_$NAME  hmm15/recout/recout_tied_models_$NAME.mlf >> hmm15/res.txt     

#HVite -T 0 -H hmm15/macros -H hmm15/hmmdefs -S $TOPDIR/scp/$TESTSCP -l '*' -i hmm15/recout/recout_words_$NAME.mlf -w lang/bigram5k.lat -p 0.0 -s 5.0 lang/dict_lm tiedlist_$NAME 2>>LOG.txt  1>>LOG.txt;
#bash $TOPDIR/scripts/fix_unicode.sh hmm15/recout/recout_words_$NAME.mlf > hmm15/recout/recout_words_fixed_$NAME.mlf
#HResults -I $TOPDIR/mlf/masterfile.mlf tiedlist_$NAME hmm15/recout/recout_words_fixed_$NAME.mlf >> hmm15/res.txt


