import os
import sys
from numpy import arange
import bisect
from decimal import *
import numpy as np
import math
import copy
import argparse


parser = argparse.ArgumentParser()
parser.add_argument('risci', help="Number of NCX's RISC instructions to generate", type=int)
#parser.add_argument('-c', '--cisci', help="Optional number of PE's CISC instructions to mix in", type=int)
args = parser.parse_args()



np.random.seed(42069)


def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)

def hexify(binstring):
    hstr = '%0*x' % ((len(binstring) + 3) // 4, int(binstring, 2))
    return hstr




regs = np.random.randint(20000, size=24)


instructions = ""



for _ in range(args.risci):


    whichinst = np.random.randint(26)


    # ncx_NOOP noop
    if(whichinst == 0):

        instruction.append("ncx_NOOP noop











print("\nDONE")
