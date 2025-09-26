#!/bin/bash

# Admixture analysis (estimating K from 2 to 6)
# Running Admixture with cross-validation (cv) for different K values
for k in {2..6}; do
  admixture -j2 -C 0.01 --cv admixture.bed $k > admixture.log$k.out
done