#!/bin/bash

#
# function prediction for a single query protein
#
set -eux

CPUS=24
CPFP_DIR="$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)/../"
TRR_DIR="${CPFP_DIR}/trRosetta"
HHBLITS_BIN="hhblits"
HHBLITS_DB="${CPFP_DIR}/uniclust30/uniclust30_2018_08/uniclust30_2018_08"

fasta="${1}"
basename="${fasta##*/}"
query="${basename%.*}"

# create dir for output
OUTDIR="output/${query}"
mkdir -p ${OUTDIR}

# MSA
$HHBLITS_BIN \
    -i ${fasta} \
    -d ${HHBLITS_DB} \
    -o ${OUTDIR}/${query}.hhr \
    -oa3m ${OUTDIR}/${query}.a3m \
    -n 3 -id 99 -cov 50 -diff inf \
    -cpu ${CPUS}

# trRosetta
export KMP_WARNINGS="0"          # suppress some useless messages
export OMP_NUM_THREADS=${CPUS}
python3 \
    ${TRR_DIR}/network/predict.py \
    -m ${TRR_DIR}/model2019_07 \
    ${OUTDIR}/${query}.a3m \
    ${OUTDIR}/${query}.npz

# convert
python3 ${CPFP_DIR}/prediction/x-convert.py \
    ${OUTDIR}/${query}.npz

${CPFP_DIR}/bin/DCount \
    -i ${OUTDIR}/${query}.gw \
    -o ${OUTDIR}/${query}.ndump

# GRalign
for i in `ls -1 ${CPFP_DIR}/Database|head -n 2`; do
    echo "\
        ${CPFP_DIR}/bin/GR-Align_1.5 \
            -q <(printf ${query}) \
            -r ${OUTDIR} \
            -t <(find ${CPFP_DIR}/Database/${i} -name '*.gw' | rev | cut -d '/' -f 1 | rev | cut -f 1 -d '.') \
            -u ${CPFP_DIR}/Database/${i} \
            -o ${OUTDIR}/gr_${i} \
        ";
done | parallel -j ${CPUS}

# sort by similarity
cat ${OUTDIR}/gr_* | sort | uniq | sort -k6,6gr > ${OUTDIR}/${query}.gr.short
rm -rf ${OUTDIR}/gr_*

# extend duplication
python3 ${CPFP_DIR}/prediction/x-extend.py ${CPFP_DIR}/prediction/knowledge/dup.txt ${OUTDIR}/${query}.gr.short > ${OUTDIR}/${query}.gr

# GO prediction
python3 ${CPFP_DIR}/prediction/x-calcGO.py \
    ${OUTDIR}/${query}.gr \
    ${CPFP_DIR}/prediction/knowledge/enriched/enriched_annotation.txt \
        > ${OUTDIR}/${query}.prediction
