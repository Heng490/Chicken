#!/bin/bash
# FST (Fixation Index)
# Calculate FST between two populations (A and B) using vcftools
vcftools --vcf chicken.vcf \
         --weir-fst-pop A.txt \
         --weir-fst-pop B.txt \
         --out game \
         --fst-window-size 100000 \
         --fst-window-step 10000