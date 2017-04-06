#!/bin/bash
set -e
export PATH=/usr/local/bin:$PATH

if [ ! -d /home/outputs ];then
	mkdir -p /home/outputs
fi
#cd /home/outputs

if [ $BATCH_COMPUTE_DAG_INSTANCE_ID -eq 0 ]; then
    genomic_interval=X
elif [ $BATCH_COMPUTE_DAG_INSTANCE_ID -lt 23 ]; then
    genomic_interval=$BATCH_COMPUTE_DAG_INSTANCE_ID
elif [ $BATCH_COMPUTE_DAG_INSTANCE_ID -eq 23 ]; then
    genomic_interval=Y
elif [ $BATCH_COMPUTE_DAG_INSTANCE_ID -eq 24 ]; then  
    genomic_interval=M
elif [ $BATCH_COMPUTE_DAG_INSTANCE_ID -eq 25 ]; then
    genomic_interval=other
else
    genomic_interval=unmapped
fi

export inputs_dir=/home/inputs
export outputs_dir=/home/outputs
export reference=/home/references/$REFERENCE_NAME

#export RGinfo="@RG\tID:$RGID1\tSM:$SAMPLE_NAME\tPL:$PLATFORM\tLB:$LIBRARY1\tPU:$LINE1"
#export read1=$inputs_dir/${RGID1_READ1}.0$num.gz
#export read2=$inputs_dir/${RGID1_READ2}.0$num.gz
#export prefix=${SAMPLE_NAME}_${RGID1}_$chr
#export bamfile=${prefix}.bam
#export sorted_bamfile=sorted_${prefix}.bam

export chr=$genomic_interval
export mkdup_bamfile=$outputs_dir/${SAMPLE_NAME}_chr$chr.bam

# picard MarkDuplicates  
# input:NA12878_group1_0_chrM.bam 
# output: mkdup_$bamfile
echo "java -Xmx5g -jar picard.jar MarkDuplicates \\" > picard_$chr.sh

SPLIT=$(($SPLIT-1))
for j in `seq 1 $RGNUM`;do 
	var=RGID${j}
	rgid=`eval echo '$'"$var"`
	for n in `seq 0 $SPLIT`;do
		echo "I=$inputs_dir/${SAMPLE_NAME}_${rgid}_${n}_chr$chr.bam \\" >> picard_$chr.sh
	done
done
echo "O=$mkdup_bamfile M=metrics_file VALIDATION_STRINGENCY=STRICT \\" >> picard_$chr.sh

#index 
# input: $sorted_bamfile
# output:index_file
echo "&& samtools index $mkdup_bamfile" >> picard_$chr.sh

#end
#echo "rm $sorted_bamfile ${sorted_bamfile}.bai $bamfile " >>picard_$chr.sh

cat picard_$chr.sh
sh picard_$chr.sh
