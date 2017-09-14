#!/bin/sh

#This script is for preparing VCF files for each chromosome, which can then be uploaded to the UMich imputation server
#Instructions: https://imputationserver.sph.umich.edu/start.html#!pages/help
#Uses vcftools: https://vcftools.github.io/perl_module.html
#Uses bgzip from hstlib: http://www.htslib.org/doc/tabix.html 
#   -as a note had to install these into the directory as so:
#   cd /path/to/uncompressed/program/directory
#   ./configure --prefix=/path/to/uncompressed/program/directory
#   make
#   make install

module load plink

echo "Enter name of study population (e.g. WSC, MrOS, APOE), followed by [ENTER]: "
read study

echo "Enter number of genotype/chip/array pseudocohorts, followed by [ENTER]: "
read cohortnum

# gather genotype/chip/array pseudocohort(s) names into an array called "list"
for i in {1..$cohortnum}
do
	echo "Enter name(s) of genotype/chip/array pseudocohort(s), separated by spaces, followed by [ENTER]: "
	read cohortnames
	list=($cohortnames)
done

workDir=$PWD

for k in "${list[@]}"
do
	mkdir -p $workDir/${k}_4UMich_imputation
	

	
	for i in {1..26}
	do
		if [[ ${#i} -lt 2 ]] ; then
			inputNo="0${i}"
		else
			inputNo="${i}"
		fi
		plink --bfile ${k}_NOdups_aligned --chr ${i} --recode vcf --out $workDir/${k}_4UMich_imputation/${inputNo}_${k}_${study}_4UMich
	done
done

for k in "${list[@]}"
do
	for i in {01..26}
	do
		/srv/gsfs0/projects/mignot/PLMGWAS/vcftools-vcftools-1d27c24/src/perl/vcf-sort $workDir/${k}_4UMich_imputation/${i}_${k}_${study}_4UMich.vcf | /srv/gsfs0/projects/mignot/PLMGWAS/htslib-1.5/bgzip -c > $workDir/${k}_4UMich_imputation/${k}_${study}_chr${i}_4UMich.vcf.gz
	done
done

###next step if above file uploads fail, now that position duplicates are resolved
for k in "${list[@]}"
do
	for i in {01..26}
	do
		/srv/gsfs0/projects/mignot/PLMGWAS/Software_prep4UMich_impute/checkVCF.py -r /srv/gsfs0/projects/mignot/PLMGWAS/Software_prep4UMich_impute/hs37d5.fa -o out $workDir/${k}_4UMich_imputation/${k}_${study}_chr${i}_4UMich.vcf.gz
	done
done


### OLD garbage ###
#cat <<EOF >${k}_runSNPflip.sh
#module load python/2.7
#export PYTHONPATH=~/python/lib/python2.7/site-packages/:$PYTHONPATH
#
#/srv/gsfs0/home/logands/python/bin/snpflip -b $workDir/${k}_NOdups.bim -f /srv/gsfs0/projects/mignot/PLMGWAS/snpflip-master/human_g1k_v37.fasta -o $workDir/${k}_snpflip_output
#EOF
#	chmod +x ${k}_runSNPflip.py #make it executable
#	module load python
#	python ${k}_runSNPflip.py

###Moved all of this into the QCnew.sh script
#	#Doing the following because duplicates were found in checkVCF.py, but even these PLINK steps doesn't remove all of the duplicates
#	plink --bfile ${k}_ready4prephase --list-duplicate-vars ids-only suppress-first --out ${k}_BPduplicates
#	plink --bfile ${k}_ready4prephase --exclude ${k}_BPduplicates.dupvar --make-bed --out ${k}_NoPLINKdups
#	#More BP duplicates need removal
#	awk 'n=x[$1,$4]{print n"\n"$0;} {x[$1,$4]=$0;}' ${k}_NoPLINKdups.bim > ${k}_reference.dups #pulls duplicated positions by chromosome
#	awk '{print $2}' ${k}_reference.dups > ${k}_Position.dups #gets a list of all rsIDs/SNP IDs for removal
#	plink --bfile ${k}_NoPLINKdups --exclude ${k}_Position.dups --make-bed --out ${k}_NOdups #excludes duplicates
#
#cat <<EOF >${k}_REMOVEDpositionDuplicates.txt
#These rsIDs/SNP IDs were excluded, due to duplication at base positions:
#
#EOF
#
#	cat ${k}_BPduplicates.dupvar >> ${k}_REMOVEDpositionDuplicates.txt
#	cat ${k}_Position.dups >> ${k}_REMOVEDpositionDuplicates.txt
#	
#	#Doing a strand orientation/alignment check
#	#Used snpflip <https://github.com/biocore-ntnu/snpflip> via the SCG Cluster by <https://web.stanford.edu/group/scgpm/cgi-bin/informatics/wiki/index.php/Python>
#	#Need to install it first: pip install snpflip
#	# -Also housed /srv/gsfs0/projects/mignot/PLMGWAS/snpflip-master if you want it
#	# -Navigate into the directory "snpflip-master"
#	# -module load python
#	# -pip install --user snpflip
#	#OR can install in your home directory:
#	# -Navigate to your home directory: /srv/gsfs0/home/{yourSUNetID}
#	# -module load python/2.7
#	# -mkdir -p ~/python 
#	# -pip install --ignore-installed --install-option="--prefix=~/python/" /path/to/snpflip-master
#	# -if doing this, the python script using snpflip must contain: module load python/2.7 export PYTHONPATH=~/python/lib/python2.7/site-packages/:$PYTHONPATH
#	#Also need to download the appropriate build reference genome:
#	# -from the snpflip GitHub respository's link: <http://ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz>
#	# -I have also stored them in the /srv/gsfs0/projects/mignot/PLMGWAS/snpflip-master directory
#	
#	module load python/2.7
#	export PYTHONPATH=~/python/lib/python2.7/site-packages/:$PYTHONPATH
#	/srv/gsfs0/home/logands/python/bin/snpflip -b $workDir/${k}_NOdups.bim -f /srv/gsfs0/projects/mignot/PLMGWAS/snpflip-master/human_g1k_v37.fasta -o $workDir/${k}_snpflip_output
#	plink --bfile ${k}_NOdups --flip ${k}_snpflip_output.reverse --exclude ${k}_snpflip_output.ambiguous --make-bed --out ${k}_NOdups_aligned