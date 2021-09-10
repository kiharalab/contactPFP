#!/usr/bin/env python3

import sys
import os


def main():
    # read duplication information
    dup = {}
    with open(sys.argv[1], "rt") as f:
        for line in f:
            l = [x.strip().split("|")[1] for x in line.split("\t")[1].split(",")]
            dup[l[0]] = l[1:]

    # read and print through ranking
    # if you found the duplication, extend
    with open(sys.argv[2], "rt") as f:
        for line in f:
            if line.startswith("Query"): continue
            l = line.split()
            print("\t".join(l))
            if l[1] in dup:
                for x in dup[l[1]]:
                    print("\t".join([l[0], x] + l[2:]))


if __name__ == "__main__":
    main()
