################################
MLFFILE=$1; #master mlf file used
################################
# set enviroment variables
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8

# write global log
echo "* `date` : "  $0 $1  >> LOG_GLOBAL.txt

#########################
#MLF FILES
rm -f -r mlf;
mkdir mlf;

#copy masterfile removing _ making lowercase etc

#prepare intermediate file with filenames and transcriptions in single separated lines
tr '\n' ' ' < $MLFFILE | sed -e 's/" /" \n/g' -e 's/ \. /\n\.\n/g' -e 's/# /#\n/' > mlf/masterfile_alt.txt

#extract and process texts and files names remove interpunction
grep -v "[*\.#]" mlf/masterfile_alt.txt | tr '_' ' ' | sed -e 's/^\(.*\)$/\L\1/g' -e "s/['-]//g" -e 's/$/| ./g' > mlf/trans.txt;
grep -e '"' mlf/masterfile_alt.txt > mlf/files.txt;

#create a new processed mlf file
echo '#!MLF!#' > mlf/masterfile.mlf
paste mlf/files.txt mlf/trans.txt -d'|' | tr '|' '\n' | tr ' ' '\n'  | sed '/^$/d' >> mlf/masterfile.mlf  

#########################
#LANGUAGE
rm -f -r lang;
mkdir lang;

cd lang;

########################
# get words list
grep -v '[\.#"]' ../mlf/masterfile.mlf | sort | uniq | sed '/^$/d' > wlist;

########################
#prepare base dictionary without sp
perl ../scripts/makeTranscription.pl SAMPA < wlist > dict_base;

########################
# to get order in dictionary accepted by HTK 
export LC_ALL=L

# get dictionaries
echo -e "sil\tsil" > temp_file 
cat dict_base temp_file |  sort -k1 -d`echo -e "\t"` > dict_nosp
rm temp_file;

#with sp
sed -e 's/^\(.*\)$/\1 sp/g' dict_base > temp_file;
echo -e "sil\tsil" >>temp_file;
sort -k1 -d`echo -e "\t"` temp_file > dict_sp;

#both
cat dict_sp dict_nosp |  sort | uniq > dict_sp_nosp

#switch back to polish
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8
########################
#prepare monophones lists
cut -f2 -d"`echo -e "\t"`" dict_base | tr ' ' '\n' | sort | uniq | sed '/^$/d' > monophones0

#add silence models
echo "sil" >> monophones0; 
cat monophones0 > monophones1;
echo "sp" >> monophones1;

########################
#prepare transcripts
cd ../mlf

#prepare commands
#mkphones0.led
echo "EX"  > mkphones0.led; #expand
echo "IS sil sil"  >> mkphones0.led; #add sils
echo "DE sp" >> mkphones0.led; #delets sp's
#mkphones1.led
echo "EX"  > mkphones1.led; #expand
echo "IS sil sil"  >> mkphones1.led; #add sils

#make phones0.mlf
HLEd -T 1 -l '*' -d ../lang/dict_sp -i phones0.mlf mkphones0.led masterfile.mlf
#make phones1.mlf
HLEd -T 1 -l '*' -d ../lang/dict_sp -i phones1.mlf mkphones1.led masterfile.mlf

#end script
cd ..