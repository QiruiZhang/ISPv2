import sys
import re
import argparse
import numpy as np
from   pprint import pprint
parser = argparse.ArgumentParser()
parser.add_argument("infile", help="sram pattern dump file to parse")
parser.add_argument("--verbose", help="print swap counts for every bank",action='store_true')
args = parser.parse_args()

np.random.seed(8675309)

####################################################################################################


try:
    fd = open(args.infile)
except (...):
    print("ERROR reading %s" % args.infile)
    exit(1)


lines = fd.read()

lines = lines.split('\n')



# 4 supersets of
# 6 sets of
# 4 banks of
# sram modules that have 4 arrays
shared_accesses = np.zeros((4,6,4,4))
total_shared_swaps = np.zeros((4,6,4))
shared_hilow = np.zeros((4,6,4,4))
for i in range(0,4):
    for j in range(0,6):
        for k in range(0,4):
            if(np.random.randint(1) % 2):
                shared_hilow[i][j][k][0] = 1
                shared_hilow[i][j][k][1] = 0
            else:
                shared_hilow[i][j][k][0] = 0
                shared_hilow[i][j][k][1] = 1
            if(np.random.randint(1) % 2):
                shared_hilow[i][j][k][2] = 1
                shared_hilow[i][j][k][3] = 0
            else:
                shared_hilow[i][j][k][2] = 0
                shared_hilow[i][j][k][3] = 1

# 2 sets of
# 2 banks of
# sram modules that have 2 arrays
local_accesses = np.zeros((2,2,2))
total_local_swaps = np.zeros((2,2))
local_hilow = np.zeros((2,2,2))
for i in range(0,2):
    for j in range(0,2):
        if(np.random.randint(1) % 2):
            local_hilow[i][j][0] = 1
            local_hilow[i][j][1] = 0
        else:
            local_hilow[i][j][0] = 0
            local_hilow[i][j][1] = 1

# 2 sets of
# 2 banks of
# sram modules that have 2 arrays
weight_accesses = np.zeros((2,2,2))
total_weight_swaps = np.zeros((2,2))
weight_hilow = np.zeros((2,2,2))
for i in range(0,2):
    for j in range(0,2):
        if(np.random.randint(1) % 2):
            weight_hilow[i][j][0] = 1
            weight_hilow[i][j][1] = 0
        else:
            weight_hilow[i][j][0] = 0
            weight_hilow[i][j][1] = 1


# 2 banks of
# sram modules that have 4 arrays
imem_accesses = np.zeros((2,4))
total_imem_swaps = np.zeros((2))
imem_hilow = np.zeros((2,4))
for i in range(0,2):
    if(np.random.randint(1) % 2):
        imem_hilow[i][0] = 1
        imem_hilow[i][1] = 0
    else:
        imem_hilow[i][0] = 0
        imem_hilow[i][1] = 1
    if(np.random.randint(1) % 2):
        imem_hilow[i][2] = 1
        imem_hilow[i][3] = 0
    else:
        imem_hilow[i][2] = 0
        imem_hilow[i][3] = 1


####################################################################################################



def do_sharedmem_swap(isuper, iset, ibank, iarray):

    global total_shared_swaps

    # was this bank low?
    if(shared_hilow[isuper][iset][ibank][iarray] == 0):
        # yes, do nothing
        return
    else:
        # no, need to swap this array
        total_shared_swaps[isuper][iset][ibank] += 1
    
        # first, check if we can swap with array [0]
        if(shared_hilow[isuper][iset][ibank][0] == 0):
            # yes, so do it
            shared_hilow[isuper][iset][ibank][0] = 1
            shared_hilow[isuper][iset][ibank][iarray] = 0
            return
        else:
            # no, so find the next free one
            # (we'll automatically skip iarray since we
            #  already know it equals 1)
            for i in range(1,4):
                if(shared_hilow[isuper][iset][ibank][i] == 0):
                    shared_hilow[isuper][iset][ibank][i] = 1
                    shared_hilow[isuper][iset][ibank][iarray] = 0
                    return

    print("do_sharedmem_swap: something went very, very wrong :-(")
    exit(1)


def do_localmem_swap(iset, ibank, iarray):
    global total_local_swaps
    # was this bank low?
    if(local_hilow[iset][ibank][iarray] == 0):
        # yes, do nothing
        return
    else:
        # no, need to swap this array
        total_local_swaps[iset][ibank] += 1
        # first, check if we can swap with array [0]
        if(local_hilow[iset][ibank][0] == 0):
            # yes, so do it
            local_hilow[iset][ibank][0] = 1
            local_hilow[iset][ibank][iarray] = 0
            return
        else:
            # no, so find the next free one
            if(local_hilow[iset][ibank][1] == 0):
                local_hilow[iset][ibank][1] = 1
                local_hilow[iset][ibank][iarray] = 0
                return
    print("do_localmem_swap: something went very, very wrong :-(")
    exit(1)
                    
def do_weightmem_swap(iset, ibank, iarray):
    global total_weight_swaps
    # was this bank low?
    if(weight_hilow[iset][ibank][iarray] == 0):
        # yes, do nothing
        return
    else:
        # no, need to swap this array
        total_weight_swaps[iset][ibank] += 1
        # first, check if we can swap with array [0]
        if(weight_hilow[iset][ibank][0] == 0):
            # yes, so do it
            weight_hilow[iset][ibank][0] = 1
            weight_hilow[iset][ibank][iarray] = 0
            return
        else:
            # no, so find the next free one
            if(weight_hilow[iset][ibank][1] == 0):
                weight_hilow[iset][ibank][1] = 1
                weight_hilow[iset][ibank][iarray] = 0
                return
    print("do_weightmem_swap: something went very, very wrong :-(")
    exit(1)

def do_imem_swap(ibank, iarray):
    global total_imem_swaps
    # was this bank low?
    if(imem_hilow[ibank][iarray] == 0):
        # yes, do nothing
        return
    else:
        # no, need to swap this array
        total_imem_swaps[ibank] += 1
    
        # first, check if we can swap with array [0]
        if(imem_hilow[ibank][0] == 0):
            # yes, so do it
            imem_hilow[ibank][0] = 1
            imem_hilow[ibank][iarray] = 0
            return
        else:
            # no, so find the next free one
            # (we'll automatically skip iarray since we
            #  already know it equals 1)
            for i in range(1,4):
                if(imem_hilow[ibank][i] == 0):
                    imem_hilow[ibank][i] = 1
                    imem_hilow[ibank][iarray] = 0
                    return
    print("do_imem_swap: something went very, very wrong :-(")
    exit(1)



cycles_with_some_access = 0
acc128 = 0
acc256 = 0
acc32 = 0
for x in lines:
    sp = x.split(' ')
    if(sp[0] == "Edge:"):
        cycles_with_some_access += 1
        continue

    if(sp[0] == "SHARED"):
        acc128 += 1
        if(int(sp[len(sp)-1]) < 128):
            shared_accesses[int(sp[3])][int(sp[5])][int(sp[7])][0] += 1
            do_sharedmem_swap(int(sp[3]),int(sp[5]),int(sp[7]),0)
        elif(int(sp[len(sp)-1]) < 256):
            shared_accesses[int(sp[3])][int(sp[5])][int(sp[7])][1] += 1
            do_sharedmem_swap(int(sp[3]),int(sp[5]),int(sp[7]),1)
        elif(int(sp[len(sp)-1]) < 384):
            shared_accesses[int(sp[3])][int(sp[5])][int(sp[7])][2] += 1
            do_sharedmem_swap(int(sp[3]),int(sp[5]),int(sp[7]),2)
        elif(int(sp[len(sp)-1]) < 512):
            shared_accesses[int(sp[3])][int(sp[5])][int(sp[7])][3] += 1
            do_sharedmem_swap(int(sp[3]),int(sp[5]),int(sp[7]),3)

    elif(sp[0] == "LOCAL"):
        acc256 += 1
        if(int(sp[len(sp)-1]) < 128):
            local_accesses[int(sp[3])][int(sp[5])][0] += 1
            do_localmem_swap(int(sp[3]),int(sp[5]),0)
        else:
            local_accesses[int(sp[3])][int(sp[5])][1] += 1
            do_localmem_swap(int(sp[3]),int(sp[5]),1)

    elif(sp[0] == "WEIGHT"):
        acc256 += 1
        if(int(sp[len(sp)-1]) < 128):
            weight_accesses[int(sp[3])][int(sp[5])][0] += 1
            do_weightmem_swap(int(sp[3]),int(sp[5]),0)
        else:
            weight_accesses[int(sp[3])][int(sp[5])][1] += 1
            do_weightmem_swap(int(sp[3]),int(sp[5]),1)
        
    elif(sp[0] == "IMEM"):
        acc128 += 1
        if(int(sp[len(sp)-1]) < 128):
            imem_accesses[int(sp[3])][0] += 1
            do_imem_swap(int(sp[3]),0)
        elif(int(sp[len(sp)-1]) < 256):
            imem_accesses[int(sp[3])][1] += 1
            do_imem_swap(int(sp[3]),1)
        elif(int(sp[len(sp)-1]) < 384):
            imem_accesses[int(sp[3])][2] += 1
            do_imem_swap(int(sp[3]),2)
        elif(int(sp[len(sp)-1]) < 512):
            imem_accesses[int(sp[3])][3] += 1
            do_imem_swap(int(sp[3]),3)

    elif(sp[0] == "ACCUM"):
        acc32 += 1


print("\nCycles with any mem access: %d\n" % cycles_with_some_access)
print("Total Sharedmem Swaps: %d" % np.sum(total_shared_swaps))
print("Total Localmem Swaps: %d" % np.sum(total_local_swaps))
print("Total Weightmem Swaps: %d" % np.sum(total_weight_swaps))
print("Total Imem Swaps: %d\n" % np.sum(total_imem_swaps))
print("Total 128x512 accesses: %d" % acc128)
print("Total 256x256 accesses: %d" % acc256)
print("Total 32x32 accesses: %d" % acc32)

if(args.verbose):
    print("Shared swaps:")
    pprint(total_shared_swaps)
    print("\n\nLocal swaps:")
    pprint(total_local_swaps)
    print("\n\nWeight swaps:")
    pprint(total_weight_swaps)
    print("\n\nImem swaps:")
    pprint(total_imem_swaps)
