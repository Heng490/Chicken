#!/bin/bash
# PCA (Principal Component Analysis)
# Running PCA with PLINK using VCF format input and specifying 10 components
plink --vcf ind.vcf --pca 10 --threads 5 --out pca --allow-extra-chr