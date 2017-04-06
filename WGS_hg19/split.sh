#!/bin/bash
set -e
export PATH=/usr/local/bin:$PATH

if [ ! -d /home/outputs ];then
        mkdir -p /home/outputs
fi
#cd /home/outputs

export inputs_dir=/home/inputs
export outputs_dir=/home/outputs

export i=$(($BATCH_COMPUTE_DAG_INSTANCE_ID+1))

for j in `seq 1 2`;do  
	{
var=RGID${i}_READ${j}
reads=`eval echo '$'"$var"`
read=$inputs_dir/$reads
# split reads
echo "perl ./split.pl $SPLIT $read $outputs_dir";
perl ./split.pl $SPLIT $read $outputs_dir
	}&
done
wait
