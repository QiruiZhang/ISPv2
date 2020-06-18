import os
import numpy as np
import math
import binascii
import argparse


###################################################
# March 14: I forgot what this script is used for



parser = argparse.ArgumentParser(description='SRAM out files from binary to signed 2\'s compliment')
parser.add_argument("set_num", help="Which set do you want to convert? (Will always do 4 banks within a set)")
parser.add_argument('-u', "--unified", help="Run on unified NE SRAM data files", action="store_true")
#parser.add_argument("--c1", help="Run on a conv1/oa_*_* file", action="store_true")
#parser.add_argument("--p1", help="Run on a pool1/oa_*_* file", action="store_true")
parser.add_argument('-s', "--sim_oa", help="Run on a sim_oa_*_* file", action="store_true")
parser.add_argument('-z', "--omit_zeros", help="Skip words that are all zeros", action="store_true")
args = parser.parse_args()


if(not (args.unified or args.sim_oa)):
    print("ERROR: must specifiy one of -u, -o, or -s !")
    exit()



target_oc = 8
target_rows = 8
target_cols = 8


def twos_comp(val, bits):
    if(val & (1 << (bits-1))) != 0:
        val = val - (1 << bits)
    return val

def printmatrix(matrix_in):
    for oc_cnt in range (0, target_oc):
        print('oa channel: [' + str(oc_cnt) + ']')
        for row in range (0, target_rows):
            for col in range (0, target_cols):
                print(str(format(matrix_in[oc_cnt][col][row], '4d')) + '\t', end='')
            print('')

header = ""
modname = ""
if(args.unified):
    header = "unified_sram/out_"
    modname = "Shared"
#elif(args.c1):
#    header = "conv1/oa_"
#elif(args.p1):
#    header = "pool1/oa_"
elif(args.sim_oa):
    header = "sim_oa_"


if(int(args.set_num) > 1):
    print("ERROR: sim_oa sets are only 0 to 1")
    exit()

address = 0
data = []
for i in range(0,4):
    fd = open(header+str(args.set_num)+"_"+str(i)+".mem", "r")
    dataf = fd.read()
    data.append(dataf.splitlines())
    fd.close()




print("Data dims: ",end='')
print(np.array(data).shape)

matrix = np.zeros((target_oc, target_rows, target_cols), dtype=np.int)


row_cnt = 0
col_cnt = 0
c_cnt = 0

for i in range(0,2):

    vals = []
    allzeros = True
    for j in range(3,-1,-1):
        for b in range(0,target_oc):
            char = data[j][i][b*8:((b+1)*8)]
            if(char[0]=="x"):
                print("X WAS FOUND!")
                break
            else:
                vals.append(twos_comp(int(char,2), len(char)))
                if(vals[b] != 0):
                    allzeros = False

    if(not (args.omit_zeros and allzeros)):
        print(modname+"[%4d]: " % address, end='')
        for v in reversed(vals):
            print(v, end=' ')
        print('')

    print("len(vals): "+str(len(vals)))
    for v in reversed(vals):
        matrix[c_cnt][row_cnt][col_cnt] = v
        if(c_cnt+1 == target_oc):
            c_cnt = 0
            if(col_cnt+1 == target_cols):
                col_cnt = 0
                if(row_cnt+1 == target_rows):
                    break
                    #print("ERROR")
                    #print(matrix)
                    #exit()
                    #printmatrix(matrix)
                    #exit()
                else:
                    row_cnt += 1
            else:
                col_cnt += 1
        else:
            c_cnt += 1

    address += 1

printmatrix(matrix)
