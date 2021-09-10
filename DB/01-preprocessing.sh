#!/bin/zsh

#
# preprocessing
#

set -eux

SWISSPROT="uniprot_sprot.fasta"

# make uniprot unique
SWISSPROT_UNIQ="uniprot_sprot_uniq.fasta"
seqkit rmdup -s -D dup.txt ${SWISSPROT} > ${SWISSPROT_UNIQ}

# split swissprot into BATCH and single FASTA
seqkit split2 -s 1000 -w 100000 ${SWISSPROT_UNIQ}
for i in `ls ${SWISSPROT_UNIQ}.split/`; do
    b=`echo $i| cut -f 2 -d "_" | cut -f 1 -d "."`
    mkdir -p "FASTA/${b}"
    seqkit split2 -s 1 -O "FASTA/${b}" "${SWISSPROT_UNIQ}.split/${i}"
done