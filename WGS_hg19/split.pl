#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;

die "<files number> <FQ1> <outdir>" unless @ARGV==3;

my ($n,$fq1,$outdir)=@ARGV;
#my $fq1name = basename($fq1,"gz");
my $fq1name = basename($fq1);

if ($n >1){

my $n_reads = `zcat $fq1 |wc -l |cut -f1` ;
   $n_reads /= 4 ;
print STDERR "Total $n_reads reads in $fq1\n";

my $split_lines = (int( $n_reads / $n) + 1) * 4;

unless(-d "$outdir")
{
	system("mkdir -p $outdir");
}

system("zcat $fq1 | split -d -l $split_lines --filter='gzip > \$FILE.gz' - $outdir/$fq1name.") == 0 or die "split failed:  $? " ;
}elsif($n==1){
	system("cp $fq1 $outdir/$fq1name.00.gz;");
	
}else{print "Give the right SPLIT number!!!\n"}
