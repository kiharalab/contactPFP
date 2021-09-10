#!/bin/zsh

#
# run HHblits for every proteins in uniprot
#

set -xe

HHBLITS_BIN="${HOME}/local/pkg/hh-suite-3.2.0/bin/hhblits"
HHBLITS_DB="${HOME}/Share/seqDB/uniclust30_2018_08/uniclust30_2018_08"

for i in `seq 1 475`; do
    BATCH=`printf "%03d" ${i}`
    mkdir -p "STAGE1/${BATCH}" "STAGE1_tmp/${BATCH}"
    
    for j in `seq 1 1000`; do
        PART=`printf "%03d" ${j}`
        FASTAFILE="FASTA/${BATCH}/uniprot_sprot_uniq.part_${BATCH}.part_${PART}.fasta"
        SPID=`head -n 1 ${FASTAFILE} | cut -f 2 -d "|"`

        # run HHblits
        $HHBLITS_BIN \
        -i ${FASTAFILE} \
        -d ${HHBLITS_DB} \
        -o STAGE1_tmp/${BATCH}/${SPID}.hhr \
        -oa3m STAGE1/${BATCH}/${SPID}.a3m \
        -n 3 \
        -id 99 \
        -cov 50 \
        -diff inf \
        -cpu 8
    done
done
