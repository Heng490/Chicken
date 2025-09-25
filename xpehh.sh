#!/bin/bash



# XPEHH (Cross-Population Extended Haplotype Homozygosity)
# Performing XPEHH analysis comparing two populations (pop1 and pop2)
selscan –xpehh –vcf <pop1_vcf> --vcf-ref <pop2_vcf> --map <mapfile> --out <outfile>