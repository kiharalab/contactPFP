#!/usr/bin/env python3

import sys
import os
import itertools
import zipfile
from multiprocessing import Pool
from tqdm import tqdm
import numpy as np

dirnum = None
o2t = {
    'C': 'CYS', 'D': 'ASP', 'S': 'SER', 'Q': 'GLN', 'K': 'LYS', 'I': 'ILE',
    'P': 'PRO', 'T': 'THR', 'F': 'PHE', 'N': 'ASN', 'G': 'GLY', 'H': 'HIS',
    'L': 'LEU', 'R': 'ARG', 'W': 'TRP', 'A': 'ALA', 'V': 'VAL', 'E': 'GLU',
    'Y': 'TYR', 'M': 'MET'
}


def main():
    """
    list of the files in each directory and convert into the contact file
    parameters:
        argv[1]: indir_base
        argv[2]: outdir_base
        argv[3]: job_num
    """
    global dirnum
    for i in os.listdir(sys.argv[1]):
        dirnum = "{:03d}".format(int(i))
        with Pool(8) as p:
            imap = p.imap(function, os.listdir(os.path.join(sys.argv[1], dirnum)))
            result = list(tqdm(imap, total=1000, desc=dirnum))


def np2c_tR(d):
    # matrix is L*L*37, axis = 2 is channel and channel[0] is trash
    # 1. sum 0-8 A bins probabirity, symmetrize, make a list
    res = []
    for i, j in list(itertools.combinations(range(d.shape[0]),2)):
        if abs(j - i) < 3: continue
        res.append([
            i,
            j,
            (np.sum(d[i, j, 1:21]) + np.sum(d[j, i, 1:21])) / 2
        ])
    return sorted(res, key=lambda x: -x[2])
# 8 A: [1:13]
# 10A: [1:17]
# 12A: [1:21]


def function(fn):
    try:
        d = np.load(os.path.join(sys.argv[1], dirnum, fn))["dist"]
    except OSError:
        return
    except zipfile.BadZipFile:
        print(fn)
        return
    if d.shape[0] < 20 or d.shape[0] > 2000: return
    # calc contact
    cl = np2c_tR(d)
    # get sequence from a3m
    with open(os.path.join("STAGE1", dirnum, fn.split(".")[0]+".a3m"), "rt") as f:
        for line in f:
            if line.startswith(">"): continue
            s = line.strip()
            break

    os.makedirs(os.path.join(sys.argv[2], dirnum), exist_ok=True)
    with open(os.path.join(sys.argv[2], dirnum, fn.split(".")[0]+".gw"), "w") as f:
        print("\n".join(["LEDA.GRAPH", "string", "short"]), file=f)
        print("{}".format(d.shape[0]), file=f)
        for i, r in enumerate(s):
            print("|{"+o2t.get(r, "UNK")+"_"+str(i+1)+"}|", file=f)
        tmp = []
        for x in cl:
            if x[2] < 0.5: break
            tmp.append("{} {} 0 ".format(x[0]+1, x[1]+1)+"|{}|")
        print("{}".format(len(tmp)), file=f)
        print("\n".join(tmp), file=f)


if __name__ == "__main__":
    main()
