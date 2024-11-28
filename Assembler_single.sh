#!/bin/bash
#SBATCH --partition=mpcs.p
#SBATCH --time=12:00:00 
#SBATCH --job-name=A_singl_%J
#SBATCH --output=logs/Assembler_single_%J.out
#SBATCH --nodes=4


echo "Starting individual assembler"


module load Python
module load git
module load SPAdes
module load BLAST+
module load Miniconda3
module load FastQC
module load R


echo "Modules loaded"


datadir="/fs/dss/groups/agmedmibi/Data from Core Facility Genomics/NovaSeq-short_reads-from_Run_117"
outputdir="/fs/dss/groups/agmedmibi/Assemblies/"
blastprodir="/fs/dss/groups/agmedmibi/Assembler/blastdbs/pro/"
blast16sdir="/fs/dss/groups/agmedmibi/Assembler/blastdbs/16s/"
blast18sdir="/fs/dss/groups/agmedmibi/Assembler/blastdbs/18s/"
blastITSdir="/fs/dss/groups/agmedmibi/Assembler/blastdbs/ITS/"

cd "$datadir"
echo "$PWD"
shopt -s nullglob
subdirs=(*)

cd "${subdirs[$1]}"
echo "$PWD"
filename1=*R1_001.fastq.gz
filename2=*R2_001.fastq.gz

echo $filename1
echo $filename2

#Make subfolders
cd "$outputdir"
mkdir "${subdirs[$1]}"
cd "${subdirs[$1]}"
mkdir readQCreports


cd "$datadir/${subdirs[$1]}"
echo "$PWD"

#Do fastp filtering
source activate fastp_environ
fastp -i $filename1 -I $filename2 -o "$outputdir/${subdirs[$1]}"/filtered.R1_001.fastq.gz -O "$outputdir/${subdirs[$1]}"/filtered.R2_001.fastq.gz -h "$outputdir/${subdirs[$1]}"/readQCreports/fastp_filter_report.html
conda deactivate


#Go back to output folder
cd "$outputdir/${subdirs[$1]}"

#Do fastQC report
fastqc -o readQCreports filtered.R1_001.fastq.gz --extract
fastqc -o readQCreports filtered.R2_001.fastq.gz --extract

#Assemble genome
/fs/dss/groups/agmedmibi/Assembler/Unicycler/unicycler-runner.py -1 filtered.R1_001.fastq.gz -2 filtered.R2_001.fastq.gz -o /fs/dss/groups/agmedmibi/Assemblies/"${subdirs[$1]}"


#Do assembly stats
source activate fastp_environ
assembly-stats -t assembly.fasta >astats.txt
conda deactivate



#Blast assembled genome
echo "Blasting prokaryotic database"
cd $blastprodir
blastn -db $blastprodir/ref_prok_rep_genomes -query "$outputdir/${subdirs[$1]}"/assembly.fasta -out "$outputdir/${subdirs[$1]}"/Blast_results_pro.csv -max_target_seqs 1 -outfmt "10 qseqid sseqid staxids sscinames sblastnames scomnames pident length evalue" 

echo "Blasting 16s database"
cd $blast16sdir
blastn -db $blast16sdir/16S_ribosomal_RNA -query "$outputdir/${subdirs[$1]}"/assembly.fasta -out "$outputdir/${subdirs[$1]}"/Blast_results_16s.csv -max_target_seqs 1 -outfmt "10 qseqid sseqid staxids sscinames sblastnames scomnames pident length evalue" 

echo "Blasting 18s database"
cd $blast18sdir
blastn -db $blast18sdir/18S_fungal_sequences -query "$outputdir/${subdirs[$1]}"/assembly.fasta -out "$outputdir/${subdirs[$1]}"/Blast_results_18s.csv -max_target_seqs 1 -outfmt "10 qseqid sseqid staxids sscinames sblastnames scomnames pident length evalue" 


echo "Blasting ITS database"
cd $blastITSdir
blastn -db $blastITSdir/ITS_RefSeq_Fungi -query "$outputdir/${subdirs[$1]}"/assembly.fasta -out "$outputdir/${subdirs[$1]}"/Blast_results_ITS.csv -max_target_seqs 1 -outfmt "10 qseqid sseqid staxids sscinames sblastnames scomnames pident length evalue" 

echo "Remote Blasting first 10000bp"
cd $outputdir/"${subdirs[$1]}"
python /fs/dss/groups/agmedmibi/Assembler/first10000bp.py

cd $blastprodir
blastn -db nt -remote -query "$outputdir/${subdirs[$1]}"/first10000bp.fasta -out "$outputdir/${subdirs[$1]}"/Blast_results_remote.csv -max_target_seqs 5 -outfmt "10 qseqid sseqid staxids sscinames sblastnames scomnames stitle pident length evalue" 


cd $outputdir/"${subdirs[$1]}"


#Run resfinder
pip install resfinder
export CGE_RESFINDER_RESGENE_DB="/fs/dss/groups/agmedmibi/Assembler/resfinder_databases/resfinder_db"
export CGE_RESFINDER_RESPOINT_DB="/fs/dss/groups/agmedmibi/Assembler/resfinder_databases/pointfinder_db"
export CGE_DISINFINDER_DB="/fs/dss/groups/agmedmibi/Assembler/resfinder_databases/disinfinder_db"

echo "runnin resfinder"
python -m resfinder -o resfinder -s "other" -ifa assembly.fasta -acq -c


source activate fastp_environ

#compile data using R script

echo "Compiling R report"

until grep -Fxq "free" "/fs/dss/groups/agmedmibi/Assembler/in_use.txt"

do
  echo "occupied, wait 10s"
  sleep 10
done

echo "in_use" > "/fs/dss/groups/agmedmibi/Assembler/in_use.txt"

echo "Compiling R report, report free"
Rscript /fs/dss/groups/agmedmibi/Assembler/install_libs.r "${subdirs[$1]}"


echo "free" > "/fs/dss/groups/agmedmibi/Assembler/in_use.txt"
echo "succesfully compiled R report"

conda deactivate

echo "Copying results"

cp assembly.fasta "/fs/dss/groups/agmedmibi/Final_assemblies/assembly_${subdirs[$1]}.fasta"
cp "Analysis_report_${subdirs[$1]}.pdf"   "/fs/dss/groups/agmedmibi/Reports/"



echo "finished running"




