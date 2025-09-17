# ================================================
# Scripts developed and used in the article
# "Genome-wide Sequencing Reveals Selective Signatures for Characteristic Traits and Breed-specific Tag SNP Detection in Chinese Gamecocks".
# ================================================

# 1. Sequencing Data Analysis

# Mapping and GVCF calling for each sample
# Step 1: Perform BWA alignment using Sentieon
for i in ${sample[@]}; do
  # BWA MEM alignment step with Sentieon (multithreading for efficiency)
  $sentieon bwa mem -R "@RG\tID:GROUP_${i}\tSM:${i}\tPL:illumina" \
  -t 60 $REFERENCE ${i}_1.fastq.gz ${i}_2.fastq.gz | \
  # Sorting the aligned BAM file
  $sentieon util sort -o ${i}.sorted.bam -t 60 --sam2bam -i -
  
  # LocusCollector to collect information for recalibration
  $sentieon driver -t 60 -i ${i}.sorted.bam --algo LocusCollector --fun score_info ${i}_score.txt
  
  # Deduplication step to remove PCR duplicates
  $sentieon driver -t 60 -i ${i}.sorted.bam --algo Dedup --rmdup --score_info ${i}_score.txt \
  --metrics ${i}_dedup_metrics.txt ${i}_deduped.bam
  
  # Base recalibration using known variant sites
  $sentieon driver -r $REFERENCE -t 60 -i ${i}_deduped.bam --algo QualCal -k $known_sites ${i}_RECAL_DATA_TABLE
  
  # Haplotype calling and GVCF emission
  $sentieon driver -r $REFERENCE -t 60 -i ${i}_deduped.bam -q ${i}_RECAL_DATA_TABLE \
  --algo Haplotyper --emit_mode gvcf ${i}.gvcf
done && wait

# Step 2: Combine individual GVCF files into a single VCF
$sentieon driver -r $REFERENCE --algo GVCFtyper \
  -v a.gvcf -v b.gvcf \
  chicken_raw.vcf

# 2. Population Structure Analysis

# NJ tree construction
# Using VCF2Dis to calculate pairwise genetic distances
VCF2Dis -InPut ind.vcf -OutPut p_dis.mat

# PCA (Principal Component Analysis)
# Running PCA with PLINK using VCF format input and specifying 10 components
plink --vcf ind.vcf --pca 10 --threads 5 --out pca --allow-extra-chr

# Admixture analysis (estimating K from 2 to 10)
# Running Admixture with cross-validation (cv) for different K values
for k in {2..10}; do
  admixture -j2 -C 0.01 --cv admixture.bed $k > admixture.log$k.out
done

# 3. Selective Sweep Analysis

# FST (Fixation Index)
# Calculate FST between two populations (A and B) using vcftools
vcftools --vcf chicken.vcf \
         --weir-fst-pop A.txt \
         --weir-fst-pop B.txt \
         --out game \
         --fst-window-size 100000 \
         --fst-window-step 10000

# PI (Nucleotide Diversity)
# Calculate nucleotide diversity (Pi) within population A
vcftools --vcf chicken.vcf --keep A.txt --window-pi 100000 \
         --window-pi-step 10000 --out A_pi

# XPEHH (Cross-Population Extended Haplotype Homozygosity)
# Performing XPEHH analysis comparing two populations (pop1 and pop2)
selscan –xpehh –vcf <pop1_vcf> --vcf-ref <pop2_vcf> --map <mapfile> --out <outfile>

# 4. Breed Identification

# Tag SNP identification
# Using FST to detect tag SNPs for each breed
vcftools --vcf gamecock.vcf \
         --weir-fst-pop case_${breed}.txt \
         --weir-fst-pop cont_${breed}.txt \
         --out fst_${breed}

# Machine learning classification for breed identification
# Running a script for machine learning classification (you should have ML.R script for model training)
Rscript ML.R
