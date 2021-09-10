#!/bin/zsh

#
#
#

# generate gw files from prediction npz
python3 31-convert.py STAGE2/ CM_12A/

# generate ndump files from gw
for i in `ls -1 CM_12A/`; do
    for fn in `find CMv4/${i}/ -name "*.gw"`; do
        ${HOME}/local/pkg/GR-Align_v1.5/DCount -i ${fn} -o `echo ${fn}|sed "s/\.gw/.ndump/g"`;
    done
done
