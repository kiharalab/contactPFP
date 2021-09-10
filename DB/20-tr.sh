#!/bin/zsh

#
# distance prediction using trRosetta
#

set -eux

for i in `ls -1 STAGE1`; do
    mkdir -p "STAGE2/${i}"

    for j in `ls -1 STAGE1/${i}`; do
        pn=`echo ${j}|cut -f 3 -d "/" | cut -f 1 -d "."`
        # run trRosetta
        python3 \
        ${HOME}/local/pkg/trRosetta/network/predict.py \
        -m ${HOME}/local/pkg/trRosetta/model2019_07 \
        STAGE1/${i}/${j} \
        STAGE2/${i}/${pn}.npz
    done
done


