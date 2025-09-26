
================================================
Scripts developed and used in the article
"Genome-wide Sequencing Reveals Selective Signatures for Characteristic Traits and Breed-specific Tag SNP Detection in Chinese Gamecocks".
================================================
1. Sequencing Data Analysis
Fastq_Vcf.sh: This script is used for processing raw sequencing data (FASTQ files) and converting it into VCF format for downstream analysis.
2. Population Structure Analysis
NJ.sh: This script performs Neighbor-Joining (NJ) tree analysis to explore the population structure of the samples.
PCA.sh: This script conducts Principal Component Analysis (PCA) to assess genetic variation and clustering within the population.
admixture.sh: This script runs the ADMIXTURE algorithm to estimate individual ancestry proportions and population structure.
3. Selective Signature Analysis
FST.sh: This script calculates FST (Fixation Index) to detect population differentiation and identify regions under selection.
pi.sh: This script computes π (nucleotide diversity) to measure genetic variation within populations.
xpehh.sh: This script applies XP-EHH (Cross-Population Extended Haplotype Homozygosity) to identify selective sweeps between populations.
4. Breed Identification
Tag SNP identification
tag_snp.sh: This script identifies breed-specific tag SNPs (single nucleotide polymorphisms) to distinguish different breeds.
Machine learning classification for breed identification
ML.sh: Runs machine learning-based classification using the identified tag SNPs (requires ML.R script). The input file is ML_all.txt.

