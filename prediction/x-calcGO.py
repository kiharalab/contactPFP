#!/usr/bin/env python3

import sys
import os
from multiprocessing import Pool
from tqdm import tqdm


def norm(score, min_score, max_score):
    return (score / max_score)


def gralign_to_goterm(in_file, UniAcc2UniName, annot, category, BLIST={}, top=2):
    pred_goterms = {}
    Used = []
    Skipped = []
    NotFound = []
    with open(in_file) as f:
        for line in f:
            l = line.split()
            try:
                uniprot_id = UniAcc2UniName[l[1]]
                if uniprot_id in BLIST:
                    Skipped.append(uniprot_id)
                    continue
                score = float(l[5])
            except ValueError:
                continue
            try:
                goterms = annot[uniprot_id]
            except KeyError:
                NotFound.append(uniprot_id)
                goterms = []
                continue
            if not goterms: continue
            for goterm in goterms:
                try:
                    pred_goterms[goterm] += score
                except KeyError:
                    pred_goterms[goterm] = score
            Used.append(uniprot_id)
            if len(Used) >= top: break

    FPC_goterms = {"f": {}, "p": {}, "c": {}}
    for k, v in sorted(pred_goterms.items(), key=lambda x: -x[1]):
        FPC_goterms[category[k]][k] = v

    for category, d in FPC_goterms.items():
        if len(d) < 1: continue
        max_score = max(d.values())
        min_score = min(d.values())
        r = 1
        for k, v in sorted(d.items(), key=lambda x: -x[1]):
            confidence = norm(v, min_score, max_score)
            print("{}\t{}\t{:.3f}\t{:.3f}\t{}".format(k, category, confidence, v, r))
            r += 1

    return Used, Skipped, NotFound


def main():
    in_file = sys.argv[1]
    annot_file = sys.argv[2]

    annot = {}  # 002L_FRG3G -> [0033644, 0016021]
    with open(annot_file) as f:
        for line in f:
            k, *v = line.split()
            annot[k] = v

    # load stuffs
    UniAcc2UniName = {}  # Q8YW84 -> NDHM_NOSS1
    with open("prediction/knowledge/10-id.txt") as f:
        f.readline()
        for line in f:
            l = line.split()
            UniAcc2UniName[l[0]] = l[2] if len(l) == 3 else l[1]
    file_name_conv = {}
    with open("prediction/knowledge/mapping_final.txt") as f:
        for line in f:
            l = line.split()
            file_name_conv[l[0]] = l[1]
    category = {}  # 0000001 -> p
    with open("prediction/knowledge/category.txt") as f:
        for line in f:
            l = line.split()
            category[l[0]] = l[1]

    # ID converter2
    NEW2OLD = {}
    OLD2NEW = {}
    with open("prediction/knowledge/10-id.txt") as f:
        f.readline()
        for line in f:
            l = line.split()
            if len(l) == 3 and l[1] != l[2]:
                NEW2OLD[l[1]] = l[2]
                OLD2NEW[l[2]] = l[1]

    gralign_to_goterm(
        in_file,
        UniAcc2UniName,  # AC -> OLD + NEW
        annot,  # OLD
        category
    )


if __name__ == "__main__":
    main()
