#!/bin/bash

# Define the reference genome and other required variables
REFERENCE="/path/to/reference/genome.fa"
known_sites="/path/to/known/variants.vcf"
samples=("sample1" "sample2" "sample3")  # List your samples here

# Step 1: Perform BWA alignment and sorting for each sample
for sample in "${samples[@]}"; do
  echo "Processing $sample..."

  # Perform BWA MEM alignment (use your tool's command here)
  sentieon bwa mem -R "@RG\tID:GROUP_${sample}\tSM:${sample}\tPL:illumina" \
    -t 60 $REFERENCE ${sample}_1.fastq.gz ${sample}_2.fastq.gz | \
    sentieon util sort -o ${sample}.sorted.bam -t 60 --sam2bam -i -

  # Perform LocusCollector to collect recalibration data
  sentieon driver -t 60 -i ${sample}.sorted.bam --algo LocusCollector --fun score_info ${sample}_score.txt

  # Remove PCR duplicates using Dedup
  sentieon driver -t 60 -i ${sample}.sorted.bam --algo Dedup --rmdup --score_info ${sample}_score.txt \
    --metrics ${sample}_dedup_metrics.txt ${sample}_deduped.bam

  # Perform base recalibration using known variant sites
  sentieon driver -r $REFERENCE -t 60 -i ${sample}_deduped.bam --algo QualCal -k $known_sites ${sample}_RECAL_DATA_TABLE

  # Haplotype calling and GVCF emission
  sentieon driver -r $REFERENCE -t 60 -i ${sample}_deduped.bam -q ${sample}_RECAL_DATA_TABLE \
    --algo Haplotyper --emit_mode gvcf ${sample}.gvcf

done

# Step 2: Combine individual GVCF files into a single VCF file
echo "Combining GVCF files into a single VCF..."
sentieon driver -r $REFERENCE --algo GVCFtyper \
  -v sample1.gvcf -v sample2.gvcf -v sample3.gvcf \
  -o combined_output.vcf

echo "Analysis completed."
