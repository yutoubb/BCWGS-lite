#!/bin/bash
set -e
export PATH=/usr/local/bin:$PATH

if [ ! -d /home/outputs ];then
	mkdir -p /home/outputs
fi
#cd /home/outputs

export inputs_dir=/home/inputs
export outputs_dir=/home/outputs
export reference=/home/references/$REFERENCE_NAME
#export known_Mills_indels=/home/known/$KNOWN_Mills_indels
#export known_1000G_indels=/home/known/$KNOWN_1000G_indels
#export dbsnp=/home/known/$DBSNP

#export RGinfo="@RG\tID:$RGID1\tSM:$SAMPLE_NAME\tPL:$PLATFORM\tLB:$LIBRARY1\tPU:$LINE1"
#export read1=$inputs_dir/${RGID1_READ1}.0$chr.gz
#export read2=$inputs_dir/${RGID1_READ2}.0$chr.gz
#export prefix=${SAMPLE_NAME}_${RGID1}_$chr
#export bamfile=${prefix}.bam
#export sorted_bamfile=sorted_${prefix}.bam

#export chr=$genomic_interval
#export prefix=${SAMPLE_NAME}_chr$chr
#export mkdup_bamfile=$inputs_dir/${prefix}.bam
#export realign_bamfile=realign_${prefix}.bam
#export realign_bqsr_bamfile=realign_BQSR_${prefix}.bam
#export raw_vcf=${prefix}.raw.vcf
export final_vcf=$outputs_dir/${SAMPLE_NAME}.raw.vcf.gz

# gatk CatVariants  
# input:raw_vcf
# output:final_vcf
echo "java -Xmx5g -cp GenomeAnalysisTK.jar org.broadinstitute.gatk.tools.CatVariants \\
-R $reference -out $final_vcf --assumeSorted \\" > mergevcf_$chr.sh

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 M X Y;
do 
raw_vcf=${SAMPLE_NAME}_chr${i}.raw.vcf.gz
echo "--variant $inputs_dir/$raw_vcf \\" >> mergevcf_$chr.sh
done  

#end
#echo "rm $sorted_bamfile ${sorted_bamfile}.bai $bamfile " >>picard_$chr.sh

cat mergevcf_$chr.sh
sh mergevcf_$chr.sh
