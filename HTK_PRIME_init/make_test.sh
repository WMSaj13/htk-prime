DIR=`pwd`;
bash -x train.sh $DIR TEST balanced200plus.scp test3files.scp
bash -x train_mix.sh $DIR TEST TEST test3files.scp