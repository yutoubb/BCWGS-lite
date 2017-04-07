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
export chrnames="chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrM chrX chrY"
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
echo "./bcftools concat -O z -o $final_vcf \\" > mergevcf.sh

for i in $chrnames
do 
raw_vcf=${SAMPLE_NAME}_${i}.raw.vcf.gz
echo "$inputs_dir/$raw_vcf \\" >> mergevcf.sh
done  

#end
#echo "rm $sorted_bamfile ${sorted_bamfile}.bai $bamfile " >>picard_$chr.sh

cat mergevcf.sh
sh mergevcf.sh
