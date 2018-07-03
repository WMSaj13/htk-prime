################################
# set enviroment variables
export LC_ALL=pl_PL.utf-8
export LANG=pl_PL.utf-8

# write global log
echo "* `date` : "  $0 >> LOG_GLOBAL.txt

################################

#monophones0
paste lang/monophones0 lang/monophones0 > lang/phones0_dict

echo '$words=' | tr -d '\n' > lang/phones0.net;
grep -v 'sil' lang/monophones0 | tr '\n' '|'  >> lang/phones0.net   # add all models separated by | apart from sil
echo "sil;">> lang/phones0.net  # add sil model and EOL
echo '([sil] <$words> [sil])' >> lang/phones0.net;
HParse lang/phones0.net lang/phones0.lat

#monophones1
paste lang/monophones1 lang/monophones1 > lang/phones1_dict

echo '$words=' | tr -d '\n' > lang/phones1.net;
grep -v 'sil' lang/monophones0 | tr '\n' '|'  >> lang/phones1.net   # add all models separated by | apart from sil
echo "sil;">> lang/phones1.net  # add sil model and EOL
echo '([sil] <$words [sp]> [sil])' >> lang/phones1.net;
HParse lang/phones1.net lang/phones1.lat  

################################
#create dictionary for recog
cat lang/dict_sp_nosp > lang/tmp
echo '!ENTER [] sil' >> lang/tmp
echo '!EXIT [] sil' >> lang/tmp
sort lang/tmp > lang/dict_lm
rm lang/tmp;

################################
#create full recognition lattice
cat lang/wlist > lang/wlist_start_end
echo '!ENTER' >> lang/wlist_start_end
echo '!EXIT' >> lang/wlist_start_end

# get 2-gram
HLStats -b lang/mlf_bigram -o lang/wlist mlf/masterfile.mlf
#create recognition lattice
HBuild -n lang/mlf_bigram lang/wlist_start_end lang/bigram.lat

################################
#create 5k recogniton lattice
# get words list
grep -v '[\.#"]' mlf/masterfile.mlf | sort | sed '/^$/d' | uniq -c | sort -k1 -n -r | tr -d '[0-9 ]'| head -n 5000 > lang/wlist5k

cat lang/wlist5k > lang/wlist5k_start_end
echo '!ENTER' >> lang/wlist5k_start_end
echo '!EXIT' >> lang/wlist5k_start_end

# get 2-gram 
HLStats -b lang/mlf_bigram5k -o lang/wlist5k mlf/masterfile.mlf
#create recognition lattice
HBuild -n lang/mlf_bigram5k lang/wlist5k_start_end lang/bigram5k.lat


# 5k words loop model
echo '$words=' | tr -d '\n' > lang/loop5k.net;
cat lang/wlist5k | tr '\n' '|' | sed 's/|$/;/' >> lang/loop5k.net   # add all words separated by |
echo "" >> lang/loop5k.net 
echo '(!ENTER <$words> !EXIT)' >> lang/loop5k.net ;
HParse lang/loop5k.net  lang/loop5k.lat 


################################
#create 10k recogniton lattice
# get words list
grep -v '[\.#"]' mlf/masterfile.mlf | sort | sed '/^$/d' | uniq -c | sort -k1 -n -r | tr -d '[0-9 ]'| head -n 10000 > lang/wlist10k

cat lang/wlist10k > lang/wlist10k_start_end
echo '!ENTER' >> lang/wlist10k_start_end
echo '!EXIT' >> lang/wlist10k_start_end

# get 2-gram 
HLStats -b lang/mlf_bigram10k -o lang/wlist10k mlf/masterfile.mlf
#create recognition lattice
HBuild -n lang/mlf_bigram10k lang/wlist10k_start_end lang/bigram10k.lat


# 10k words loop model
echo '$words=' | tr -d '\n' > lang/loop10k.net;
cat lang/wlist10k | tr '\n' '|' | sed 's/|$/;/' >> lang/loop10k.net   # add all words separated by |
echo "" >> lang/loop10k.net 
echo '(!ENTER <$words> !EXIT)' >> lang/loop10k.net ;
HParse lang/loop10k.net  lang/loop10k.lat 

