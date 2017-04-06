#!/bin/bash
set -e
export PATH=/usr/local/bin:$PATH

if [ ! -d /home/outputs ];then
	mkdir -p /home/outputs
fi
#cd /home/outputs

export inputs_dir=/home/inputs
export outputs_dir=/home/outputs
export merge_bamfile=$outputs_dir/${SAMPLE_NAME}.bam

# picard MergeSamFile  
# input:NA12878_chr1.bam 
# output: mkdup_$bamfile
echo "#!/bin/bash
set -e
java -Xmx13g -jar picard.jar MergeSamFiles \\
O=$merge_bamfile \\" > mergebam.sh

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 M X Y;
do 
echo "I=$inputs_dir/${SAMPLE_NAME}_chr${i}.bam \\" >> mergebam.sh
done

echo "I=$inputs_dir/${SAMPLE_NAME}_chrother.bam I=$inputs_dir/${SAMPLE_NAME}_chrunmapped.bam \\" >> mergebam.sh
#index 
# input: $sorted_bamfile
# output:index_file
echo "&& samtools index $merge_bamfile" >> mergebam.sh

#end

cat mergebam.sh
sh mergebam.sh
