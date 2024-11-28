#!/bin/bash
#SBATCH --partition=mpcs.p
#SBATCH --time=01:00:00 
#SBATCH --job-name=Assembler_overall
#SBATCH --output=logs/Assembler_overall.out
#SBATCH --nodes=1


echo "Overall assembler started"


module load Python
module load git
module load SPAdes
module load BLAST+
module load Miniconda3




#git clone https://github.com/rrwick/Unicycler.git
#cd Unicycler
#make

#echo "Unicycler installed"


#conda create -n fastp_environ
source activate fastp_environ
#conda install assembly-stats
#conda install pandoc
conda deactivate 
#conda install -c bioconda fastp
#conda install bioconda::resfinder
pip install --force-reinstall numpy scipy



#conda create -n resfinder_environ
#source activate resfinder_environ

#conda deactivate
#conda install bioconda::resfinder

cd resfinder_databases
git clone https://bitbucket.org/genomicepidemiology/resfinder_db/
git clone https://bitbucket.org/genomicepidemiology/pointfinder_db/
git clone https://bitbucket.org/genomicepidemiology/disinfinder_db/
cd ..

echo "Modules loaded & installed"


#use this later to itnerate over full lenght of folder #### Change this line for different folder
cd "/fs/dss/groups/agmedmibi/Data from Core Facility Genomics/NovaSeq-short_reads-from_Run_117"
shopt -s nullglob
subdirs=(*)
echo "${subdirs[@]}"


#make output directory
cd "/fs/dss/groups/agmedmibi"
mkdir Assemblies
mkdir Reports
mkdir Final_assemblies
echo "free" > "/fs/dss/groups/agmedmibi/Assembler/in_use.txt"

#Start scripts
cd "/fs/dss/groups/agmedmibi/Assembler"

for i in $(seq 0 1 "${#subdirs[@]}")
do

echo $i
echo "${subdirs[$i]}"

sbatch Assembler_single.sh $i

done



