# genome_assembly_of_strains
Repository for our study to observe genome differences in highly related E. coli strains and how that related to genome assembly

#### Assembly_statistics 
Contains 95 total *E. coli* assemblies along a coverage increment using the IDBA (Peng et al., 2012) and SPAdes (Bankevich et al., 2012) assemblers

#### Supplementary_graphs 
All graphs and correlations are based on statistics from IDBA assemblies, rather than the in-text graphs based on SPAdes 

#### Strain_list.csv
This file contains the metadata of all of the raw sequencing data used in this study. The 34 strains selected to assemble over a coveage increment are SRR Numbers SRR3989774-SRR3989808, exculding SRR3989775 (*mus musculus*)

#### pipeline.sh
The script used to download, subset and assemble sequencing data, and analyze and annotate the assemblies
