#!/bin/zsh

#
# function prediction for a single query protein
#
set -eux

HHBLITS_BIN="${HOME}/local/pkg/hh-suite-3.2.0/bin/hhblits"
HHBLITS_DB="${HOME}/Share/seqDB/uniclust30_2018_08/uniclust30_2018_08"

fasta="${1}"
basename="${fasta##*/}"
query="${basename%.*}"

# create dir for output
mkdir -p "output/${query}"

if false; then
# MSA
$HHBLITS_BIN \
    -i ${fasta} \
    -d ${HHBLITS_DB} \
    -o output/${query}/${query}.hhr \
    -oa3m output/${query}/${query}.a3m \
    -n 3 -id 99 -cov 50 -diff inf \
    -cpu 24

# trRosetta
python3 \
    ${HOME}/local/pkg/trRosetta/network/predict.py \
    -m ${HOME}/local/pkg/trRosetta/model2019_07 \
    output/${query}/${query}.a3m \
    output/${query}/${query}.npz

# convert
python3 prediction/x-convert.py \
    output/${query}/${query}.npz

${HOME}/local/pkg/GR-Align_v1.5/DCount \
    -i output/${query}/${query}.gw \
    -o output/${query}/${query}.ndump

# GRalign
for i in `ls -1 CM_12A`; do
    echo "\
        ${HOME}/local/pkg/GR-Align_v1.5/GR-Align_1.5 \
            -q <(printf ${query}) \
            -r output/${query} \
            -t <(find CM_12A/${i} -name '*.gw'|cut -f 3 -d '/'|cut -f 1 -d '.') \
            -u CM_12A/${i} \
            -o output/${query}/gr_${i}"
done | parallel -j 100%

# sort by similarity
cat output/${query}/gr_* | sort | uniq | sort -k6,6gr > output/${query}/${query}.gr.short
fi
# extend duplication
python3 prediction/x-extend.py prediction/knowledge/dup.txt output/${query}/${query}.gr.short > output/${query}/${query}.gr

# GO prediction
python3 prediction/x-calcGO.py \
    output/${query}/${query}.gr \
    prediction/knowledge/enriched/enriched_annotation.txt \
        > output/${query}/${query}.prediction

