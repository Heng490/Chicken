#!/bin/bash

# Tag SNP identification
# Using FST to detect tag SNPs for each breed
vcftools --vcf gamecock.vcf \
         --weir-fst-pop case_${breed}.txt \
         --weir-fst-pop cont_${breed}.txt \
         --out fst_${breed}