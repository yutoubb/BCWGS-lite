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
#elif [ $BATCH_COMPUTE_DAG_INSTANCE_ID -eq 1 ]; then ##
    genomic_interval=Y
else
    genomic_interval=M
fi

export inputs_dir=/home/inputs
export outputs_dir=/home/outputs
export reference=/home/references/$REFERENCE_NAME
export known_Mills_indels=/home/known/$KNOWN_Mills_indels
export known_1000G_indels=/home/known/$KNOWN_1000G_indels
export dbsnp=/home/known/$DBSNP

#export RGinfo="@RG\tID:$RGID1\tSM:$SAMPLE_NAME\tPL:$PLATFORM\tLB:$LIBRARY1\tPU:$LINE1"
#export read1=$inputs_dir/${RGID1_READ1}.0$chr.gz
#export read2=$inputs_dir/${RGID1_READ2}.0$chr.gz
#export prefix=${SAMPLE_NAME}_${RGID1}_$chr
#export bamfile=${prefix}.bam
#export sorted_bamfile=sorted_${prefix}.bam

export chr=chr$genomic_interval
export prefix=${SAMPLE_NAME}_chr$genomic_interval
export mkdup_bamfile=$inputs_dir/${prefix}.bam
export realign_bamfile=realign_${prefix}.bam
export realign_bqsr_bamfile=realign_BQSR_${prefix}.bam
export raw_vcf=$outputs_dir/${prefix}.raw.vcf.gz

# gatk Realign  
# input:mkdup_bamfile
# output:realign_bamfile
echo "#!/bin/bash
set -e " > gatk_$chr.sh
#java -Xmx14g -jar GenomeAnalysisTK.jar -nt 8 -T RealignerTargetCreator \\
#-R $reference -known $known_Mills_indels -known $known_1000G_indels \\
#-I $mkdup_bamfile -o ALN.intervals -L $chr

#java -Xmx14g -jar GenomeAnalysisTK.jar -T IndelRealigner \\
#-R $reference -known $known_Mills_indels -known $known_1000G_indels \\
#-I $mkdup_bamfile --targetIntervals ALN.intervals -o $realign_bamfile
#" > gatk_$chr.sh

# gatk BQSR
# input:realign_bamfile
# output:realign_bqsr_bamfile
echo "java -Xmx14g -jar GenomeAnalysisTK.jar -nct 8 -T BaseRecalibrator \\
-R $reference -knownSites $known_Mills_indels -knownSites $known_1000G_indels -knownSites $dbsnp \\
-I $mkdup_bamfile -o sorted.realn.bam.recalibration_report.grp -L $chr

java -Xmx14g -jar GenomeAnalysisTK.jar -nct 8 -T PrintReads \\
-R $reference \\
-I $mkdup_bamfile -BQSR sorted.realn.bam.recalibration_report.grp -o $realign_bqsr_bamfile
" >> gatk_$chr.sh

# gatk BQSR
# input:realign_bamfile
# output:realign_bqsr_bamfile


echo "java -Xmx14g -jar GenomeAnalysisTK.jar -nct 8 -T HaplotypeCaller \\
-R $reference -D $dbsnp \\
-I $realign_bqsr_bamfile -o $raw_vcf \\
-L $chr \\
-stand_call_conf 30 \\
-stand_emit_conf 10 \\
-A QualByDepth \\
-A RMSMappingQuality \\
-A MappingQualityRankSumTest \\
-A ReadPosRankSumTest \\
-A FisherStrand \\
-A StrandOddsRatio \\
-A Coverage 
">> gatk_$chr.sh

#index 
# input: $sorted_bamfile
# output:index_file
#echo "samtools index $mkdup_bamfile" >> picard_$chr.sh

#end
#echo "rm $sorted_bamfile ${sorted_bamfile}.bai $bamfile " >>picard_$chr.sh

cat gatk_$chr.sh
sh gatk_$chr.sh
