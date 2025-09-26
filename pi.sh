#!/bin/bash

# PI (Nucleotide Diversity)
# Calculate nucleotide diversity (Pi) within population A
vcftools --vcf chicken.vcf --keep A.txt --window-pi 100000 \
         --window-pi-step 10000 --out A_pi