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
export otherchrbed=/home/references/$OtherChrBed

export g=$(($BATCH_COMPUTE_DAG_INSTANCE_ID/$SPLIT+1))
export num=$(($BATCH_COMPUTE_DAG_INSTANCE_ID%$SPLIT))
var1=RGID${g}_READ1
var2=RGID${g}_READ2
var3=RGID${g}
var4=LANE${g}
var5=LIBRARY${g}
r1=`eval echo '$'"$var1"`
r2=`eval echo '$'"$var2"`
rgid=`eval echo '$'"$var3"`
library=`eval echo '$'"$var5"`
line=`eval echo '$'"$var4"`

export RGinfo="@RG\\\tID:$rgid\\\tSM:$SAMPLE_NAME\\\tPL:$PLATFORM\\\tLB:$library\\\tPU:$line"

if [ $num -lt 10 ]; then
	export read1=$inputs_dir/${r1}.0$num.gz
	export read2=$inputs_dir/${r2}.0$num.gz
elif [ $num -lt 100 ]; then
	export read1=$inputs_dir/${r1}.$num.gz
	export read2=$inputs_dir/${r2}.$num.gz
else
	echo "SPLIT is biger than 99! not support"
fi

export prefix=${SAMPLE_NAME}_${rgid}_$num
export bamfile=${prefix}.bam
export sorted_bamfile=sorted_${prefix}.bam
# map to reference
# input: $read1.fq.gz, $read2.fq.gz
# output: $bamfile
echo "#!/bin/bash
set -e
bwa mem -M -t 8 -R \"$RGinfo\" $reference $read1 $read2 | samtools view -Sb - > $bamfile " > bwa_$prefix.sh

# sort
# input: $bamfile
# output: $sorted_bamfile
echo "samtools sort -@ 4 -m 3G -O bam -o $sorted_bamfile $bamfile " >>bwa_$prefix.sh

#index 
# input: $sorted_bamfile
# output:index_file
echo "samtools index $sorted_bamfile" >>bwa_$prefix.sh

#split num
# input:$sorted_bamfile
# output:num bam
echo "for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 M X Y;
do 
{	
samtools view -b $sorted_bamfile -o $outputs_dir/${prefix}_chr\$i.bam chr\$i
}&
done
samtools view -@ 4 -b -L $otherchrbed $sorted_bamfile -o $outputs_dir/${prefix}_chrother.bam &
samtools view -@ 4 -b -f 12 $sorted_bamfile -o $outputs_dir/${prefix}_chrunmapped.bam &
wait"  >> bwa_$prefix.sh

#end

cat bwa_$prefix.sh
sh bwa_$prefix.sh
