#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;

die "perl $0 <input_file> <input_fq_ossdir> <output_result_ossdir> <SPLIT> <hg19/b37> <platform> 
eg. 
	perl run_batch.pl fq-input.cfg oss://bgionline-priv/tier2/test/ oss://batchcompute-jj/WGS/ 3 b37 ILLUMINA
<fq-input>	samplename	fq1name	fq2name
"  unless @ARGV==6;
#perl run_batch.pl fq.input oss://batchcompute-jj/WGS/inputs_fqs/ oss://batchcompute-jj/WGS/ 3 b37 Illumina
#input_file
#sample	fq1 fq2
my $infile=$ARGV[0];
my $indir=$ARGV[1];
my $outdir=$ARGV[2];
my $split=$ARGV[3];
my $ref=$ARGV[4];
my $platform=$ARGV[5];
my ($pack,$reference,$dbsnp,$known1,$known2,$refoss,$knowoss,$otherbed);

if($ref eq "hg19"){
	$reference="hg19.fa";
	$pack="/root/BCWGS-Lite/WGS_hg19/";
	$dbsnp="dbsnp_138.hg19.vcf.gz";
	$known1="Mills_and_1000G_gold_standard.indels.hg19.sites.vcf";	
	$known2="1000G_phase1.indels.hg19.sites.vcf";
	$refoss="oss://batchcompute-jj/WGS/references/hg19/";
	$knowoss="oss://batchcompute-jj/WGS/references/hg19_known/";
	$otherbed="hg19.other.bed";
}elsif($ref eq "b37"){
	$reference="human_g1k_v37.fa";
	$pack="/root/BCWGS-Lite/WGS_hg19/";
	$dbsnp="dbsnp_138.b37.vcf.gz";
	$known1="Mills_and_1000G_gold_standard.indels.b37.vcf.gz";
	$known2="1000G_phase1.indels.b37.vcf.gz";
	$refoss="oss://batchcompute-jj/WGS/references/b37/";
	$knowoss="oss://batchcompute-jj/WGS/references/b37_known/";
	$otherbed="b37.other.bed";
}else{
	die "Wrong reference";
}

my %hash_fq1;
my %hash_fq2;
my %hash_lib;
my %hash_lane;
open A,$infile;
while(<A>){
	next if /^s*$/;
	chomp;
	my ($sample,$fq1,$fq2,$library,$flocell,$lane)=split;
	push @{$hash_fq1{$sample}},$fq1;
	push @{$hash_fq2{$sample}},$fq2;
	push @{$hash_lib{$sample}},$library;
	push @{$hash_lane{$sample}},$flocell."_L".$lane;
}
close A;

for my $sam (keys %hash_fq1){
	print "$sam\n";
	my $time=&gettime("yyyymmdd-hhmiss");
	my $job_name=$sam."-".$time;
	my $rgnum=$#{$hash_fq1{$sam}}+1;

	open OUT,">./$sam-$time.cfg" ||die $!;
	print OUT join ("\n","[DEFAULT]","job_name=$job_name","timeout=86400","pack=$pack","disk=system:ephemeral:100","type=bcs.a2.xlarge","\n");
	print OUT join (",","env=REFERENCE_NAME:$reference","OtherChrBed:$otherbed","DBSNP:$dbsnp","KNOWN_Mills_indels:$known1","KNOWN_1000G_indels:$known2","SAMPLE_NAME:$sam","PLATFORM:$platform","SPLIT:$split","RGNUM:$rgnum");
	
	for my $j (0..$#{$hash_fq1{$sam}}){
		my $i=$j+1;
		print OUT ",";
		print OUT join (",","RGID$i:group$i","LIBRARY$i:$hash_lib{$sam}[$j]","LANE$i:$hash_lane{$sam}[$j]","RGID$i\_READ1:$hash_fq1{$sam}[$j]","RGID$i\_READ2:$hash_fq2{$sam}[$j]");
	}
	
	print OUT "\n\ndeps=split_reads->bwa;bwa->picard_mkdup;picard_mkdup->gatk,merge_bam;gatk->merge_vcf\n\n";
	
	my $out=$outdir.$sam."-".$time;
	print OUT join ("\n","[split_reads]",
	"read_mount=$indir:/home/inputs/",
	"write_mount=$out/split_fqs/:/home/outputs/",
	"disk=system:ephemeral:400",
	"type=bcs.a2.large",
	"cmd=sh split.sh","nodes=$rgnum","\n");
	
	my $nodes=$split*$rgnum;
	print OUT join ("\n","[bwa]",
	"read_mount=$refoss:/home/references/,$out/split_fqs/:/home/inputs/",
	"write_mount=$out/bwa_results/:/home/outputs/",
	"docker=localhost:5000/bwa\@oss://batchcompute-jj/dockers/",
	"disk=system:ephemeral:100",
	"cmd=sh bwa.sh","nodes=$nodes","\n");
	
	print OUT join ("\n","[picard_mkdup]",
	"read_mount=$refoss:/home/references/,$out/bwa_results/:/home/inputs/",
	"write_mount=$out/picard_results/:/home/outputs/",
	"docker=localhost:5000/wgs\@oss://batchcompute-jj/dockers/",
	"disk=system:ephemeral:50",
	"type=bcs.a2.large",
	"cmd=sh picard.sh","nodes=27","\n");

	print OUT join ("\n","[gatk]",
	"read_mount=$refoss:/home/references/,$knowoss:/home/known/,$out/picard_results/:/home/inputs/",
	"write_mount=$out/gatk_results/:/home/outputs/",
	"docker=localhost:5000/wgs\@oss://batchcompute-jj/dockers/",
	"disk=system:ephemeral:100",
	"cmd=sh gatk.sh","nodes=25","\n");

	print OUT join ("\n","[merge_vcf]",			
	"read_mount=$refoss:/home/references/,$out/gatk_results/:/home/inputs/",
	"write_mount=$out/merge_vcf_results/:/home/outputs/",
	"docker=localhost:5000/wgs\@oss://batchcompute-jj/dockers/",
	"type=bcs.a2.large",
	"disk=system:ephemeral:100",
	"cmd=sh merge_vcf.sh","nodes=1","\n");
	
	print OUT join ("\n","[merge_bam]",
        "read_mount=$out/picard_results/:/home/inputs/",
        "write_mount=$out/merge_bam_results/:/home/outputs/",
        "docker=localhost:5000/wgs\@oss://batchcompute-jj/dockers/",
	"disk=system:ephemeral:400",
	"type=bcs.a2.large",
        "cmd=sh merge_bam.sh","nodes=1","\n");

	
	close OUT;
	#system("bcs sub --file ./$sam-$time.cfg");
}

sub gettime {
    $_ = shift;
    my $t = shift;
    (!$t) and ($t = time);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($t);
    $year += 1900;
    my $yy = substr $year,2,2;
    $mon++;
    s/yyyy/$year/gi;
    s/yy/$yy/gi;
    if ($mon < 10)  { s/mm/0$mon/gi;  } else { s/mm/$mon/gi; }
    if ($mday < 10) { s/dd/0$mday/gi; } else { s/dd/$mday/gi; }
    if ($hour < 10) { s/hh/0$hour/gi; } else { s/hh/$hour/gi; }
    if ($min < 10)  { s/mi/0$min/gi;  } else { s/mi/$min/gi; }
    if ($sec < 10)  { s/ss/0$sec/gi;  } else { s/ss/$sec/gi; }
 
    $_;
}
