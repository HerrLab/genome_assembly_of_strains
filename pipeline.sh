#!/bin/bash

# The following dependencies for this analysis script are available for download at the below links: 
# SRAtoolkit https://www.ncbi.nlm.nih.gov/sra/docs/toolkitsoft/
# seqtk https://github.com/lh3/seqtk
# SPAdes http://cab.spbu.ru/software/spades/
# QUAST http://bioinf.spbau.ru/quast

# For this script to run properly, all dependencies must be in your path. Visit https://askubuntu.com/questions/109381/how-to-add-path-of-a-program-to-path-environment-variable if you do not know how to add a program to your path.

# Exit function and trap to clean up files, to make this script a bit more robust :)

function clean_up {
	echo "We're done!"
	exit
}

trap clean_up SIGHUP SIGINT EXIT

# Set the variable $LIST to a list of SRA numbers you would like to analyze 
LIST='SRR3989779 SRR3989780'


# Set output directory you would like all of the work to be done in. Default is Coverage_analysis
OUTPUT=Coverage_analysis
mkdir ${OUTPUT}

# Downloads list of SRA numbers 
prefetch -v ${LIST}

# For loop for running entire pipeline
for ACCESSION_NUMBER in $LIST; do 
	# Converts .sra files to .fastq
	echo "Fastq-dumping, this may take some time..."
	fastq-dump --outdir ./${OUTPUT}/ --split-files ~/ncbi/public/sra/${ACCESSION_NUMBER}.sra

	# Randomly subsets fastq files. If desired, change the sequence increment corresponding to which coverage increment is desired
	for INCREMENT in $(seq 250000 250000 15000000); do
		seqtk sample -s100 ./${OUTPUT}/${ACCESSION_NUMBER}_1.fastq $INCREMENT > ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_1.fastq 
		seqtk sample -s100 ./${OUTPUT}/${ACCESSION_NUMBER}_2.fastq $INCREMENT > ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_2.fastq
		
		# Running the SPAdes genome assembler
		spades.py -1 ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_1.fastq -2 ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_2.fastq -o ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_spades_assembly
		
		# Running QUAST to generate statistics regarding the SPAdes assemblies
		quast.py -o ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_quast --no-plots ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_spades_assembly/contigs.fasta
		# Adding SRA numbers into quast report files
		sed -i "4i  SRA_number  ${x}" ./${OUTPUT}/${ACCESSION_NUMBER}_sub_${INCREMENT}_quast/report.txt	
	done
done

# Converting quast results to a transposed csv file. This file is now optimized for importation into R, the ggplot package, ect. Thanks to ghostdog74 for the awk command! https://stackoverflow.com/questions/1729824/an-efficient-way-to-transpose-a-file-in-bash  and ValeriyKr for the sed command! https://unix.stackexchange.com/questions/335276/grep-v-how-to-exclude-only-the-first-or-last-n-lines-that-match

paste ./${OUTPUT}/*_quast/report.txt | tail -n +4 |  sed 's/\(.\) /\1/g' | awk ' 
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' | sed '2 {h; s/.*/iiii/; x}; /contigs/ {x; s/^i//; x; td; b; :d; d}' | tr ' ' ',' > Total_results.csv


exit 
