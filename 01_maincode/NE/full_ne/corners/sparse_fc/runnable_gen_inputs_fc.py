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
parser.add_argument('-b', '--byte', help='Print 1 byte per line for unified_sram files', action='store_true')
args = parser.parse_args()


np.random.seed(42069)


def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)

def hexify(binstring):
    hstr = '%0*X' % ((len(binstring) + 3) // 4, int(binstring, 2))
    if(args.byte):
        return hstr[::-1]
    else:
        return hstr

# make unified_sram dir if it does not yet exist
if not os.path.exists("unified_sram"):
    os.makedirs("unified_sram")

unified_wordsize = int(128)
unified_supers = int(4)
unified_sets = int(5)
unified_banks = int(4)
unified_sram_words = int(512)
unified_huff_per_word = int(8)

##################################
#  Unified SRAM initialization   #
##################################

unified_memlist=[]

for i in range(0, unified_supers):
    unified_memlist.append([])
    for j in range(0, unified_sets):
        unified_memlist[i].append([])
        for k in range(0, unified_banks):
            unified_memlist[i][j].append([])
            for n in range(0, unified_sram_words):
                unified_memlist[i][j][k].append(str('0'*unified_wordsize))

unified_memlist_valids = np.zeros((unified_supers,unified_sets,unified_banks,unified_sram_words),dtype=bool)


ic = 256
oc = 64
kernel_size = 1 #fc
ia_size = 1
oa_size = 1
write_ia_num = 0
write_w_num = 0
write_oa_num = 1
input_data_addr = 0 # 512b world
weights_addr = 3584 # 512b world

#dense random ias 
ia = np.random.randint(-32, high=32, size=(ic, ia_size, ia_size), dtype=np.int8)

#sparse random ws 
w = np.random.randint(-32, high=32, size=(oc, ic, oa_size, oa_size), dtype=np.int8)
sparse_loc = np.random.randint(-18, high=2, size=(oc, ic, oa_size, oa_size),dtype=np.int8).clip(min=0)
sparse_w = np.multiply(w, sparse_loc).astype(np.int8)
#sparse_w = np.load() loadload
print("density: " + str(float(np.count_nonzero(sparse_w))/float(ic*oc*oa_size*oa_size)*100) + "%")

oa = np.zeros((oc, oa_size, oa_size), dtype=np.int32) 
for oc_cnt in range (0, oc):
    for ic_cnt in range (0, ic):
        for orow in range (0, oa_size):
            for ocol in range (0, oa_size):
                for irow in range (0, ia_size):
                    for icol in range (0, ia_size):
                        oa[oc_cnt][orow][ocol] = np.int32( oa[oc_cnt][orow][ocol] + np.int32(ia[ic_cnt][irow][icol]) * np.int32(sparse_w[oc_cnt][ic_cnt][orow][ocol]) )

oa_original = copy.deepcopy(oa)
oa = np.right_shift(oa, 5).astype(np.int8)


#IA SRAM
ia_mem=[]
for i in range(0, 4):
    ia_mem.append([])
    for j in range(0, 4):
        ia_mem[i].append([])
        for k in range(0,512):
            ia_mem[i][j].append("")

ia_mem_cnt=[]
for j in range(0, 4):
    ia_mem_cnt.append(0)

ia_word_total = ''
ia_word_cnt = 0
ia_addr_cnt = 0
for total_ic_cnt in range(0, int(ic/8)):
    for row in range (0, ia_size):
        for col in range (0, ia_size):
            for ic_cnt in range (0, 8):
                ia_word_total = str(bindigits(ia[total_ic_cnt*8+ic_cnt][row][col], 8)) + str(ia_word_total)
                ia_word_cnt = ia_word_cnt + 1
                for j in range(0, 4):
                    if(ia_word_cnt == 16*(j+1)):
                        ia_mem[write_ia_num][j][ia_addr_cnt] = ia_word_total
                        ia_word_total = ''
                        ia_mem_cnt[j] = ia_mem_cnt[j] + 1
                        if(j == 3):
                            ia_word_cnt = 0
                            ia_addr_cnt += 1


# super 0, set 0 = inputs
iaaddr = input_data_addr
print("Input data starting address (512b): %d (0x%X)" % (iaaddr,iaaddr))
for i in range(0, ia_addr_cnt):
    ia_superset = ((iaaddr >> 9) & 0x3)
    ia_set      = ((iaaddr >> 11) & 0x7)
    ia_word     =  (iaaddr & 0x1FF)
    for j in range(0,4):
        if(ia_mem[write_ia_num][j][i]):
            unified_memlist[ia_superset][ia_set][j][ia_word] = ia_mem[write_ia_num][j][i]
    iaaddr += 1

print("Input data end address (512b): %d (0x%X)" % (iaaddr,iaaddr))


#for i in range(0,512):
#    for j in range(0,4):
#        if(ia_mem[write_ia_num][j][i]):
#            unified_memlist[0][0][j][i] = ia_mem[write_ia_num][j][i]
#            #print(unified_memlist[0][0][j][i])
#


#W SRAM

w_word_total = '0' * 832
w_word_write= ''

bank_addr_last = []
bank_addr_set = []
skip = 0 
last_word = 0 
w_word_stored = ''
w_word_write_total = ''
RRAM_word_list = []
for j in range(0, 64):
    bank_addr_last.append(-1)
    bank_addr_set.append(0)

for total_ic_cnt in range(0, int(ic/8)):
    for row in range (0, oa_size):
        for col in range (0, oa_size):
            for ic_cnt in range (0, 8):
                #print ('looking at ic: ' + str(total_ic_cnt*8 + ic_cnt))
                for bank_id in range(0, 64):
                    bank_addr_last[bank_id] = -1
                skip = 0
                while(skip == 0 and last_word == 0):
                    #check if we shall skip this ic
                    skip = 1
                    for bank_id in range (0, 64):
                        for bank_addr in range (0, int(oc/64)):
                            if( bank_addr > bank_addr_last[bank_id] and sparse_w[bank_addr * 64 + bank_id][total_ic_cnt*8+ic_cnt][row][col] != 0 ): 
                                #print ('ic: ' + str(total_ic_cnt*8 + ic_cnt) + '; oc: ' + str(bank_addr * 64 + bank_id) + ' valid, NOT SKIPPING')
                                skip = 0

                    #last loc
                    if(row == oa_size-1 and col == oa_size-1 and total_ic_cnt*8+ic_cnt == ic-1 and skip == 1):
                        last_word = 1

                    #if not
                    if(skip == 0 or last_word == 1):
                        for bank_id in range(0, 64):
                            bank_addr_set[bank_id] = 0
                        w_word_stored = str(w_word_total)
                        w_word_total = ''
                        for bank_id in range (0, 64):
                            for bank_addr in range (0, int(oc/64)):
                                if( bank_addr > bank_addr_last[bank_id] and bank_addr_set[bank_id] == 0 and sparse_w[bank_addr * 64 + bank_id][total_ic_cnt*8+ic_cnt][row][col] != 0 ): 
                                    #print ('ic: ' + str(total_ic_cnt*8 + ic_cnt) + '; oc: ' + str(bank_addr * 64 + bank_id) + ' resolved, bank_addr: ' + str(bank_addr))
                                    tempstr = str(bindigits(bank_addr, 5)) + str(bindigits(sparse_w[bank_addr * 64 + bank_id][total_ic_cnt*8+ic_cnt][row][col], 8))
                                    #print(tempstr)
                                    w_word_total = tempstr + str(w_word_total)
                                    #print(w_word_total)
                                    bank_addr_last[bank_id] = bank_addr
                                    bank_addr_set[bank_id] = 1
                                elif(bank_addr == (oc/64 - 1) and bank_addr_set[bank_id] == 0):
                                    w_word_total = str('0' * 13) + str(w_word_total)
                                    bank_addr_set[bank_id] = 0
                                elif(bank_addr == (oc/64 - 1) and bank_addr_set[bank_id] == 1):
                                    bank_addr_set[bank_id] = 0

                        if(row == oa_size-1 and col == oa_size-1 and total_ic_cnt*8+ic_cnt == ic-1): 
                            last_word = 1
                            for bank_id in range (0, 64):
                                for bank_addr in range (0, int(oc/64)):
                                    if( bank_addr > bank_addr_last[bank_id] and sparse_w[bank_addr * 64 + bank_id][total_ic_cnt*8+ic_cnt][row][col] != 0): 
                                        #print(str(bank_addr * 64 + bank_id) + ' unsolved')
                                        last_word = 0

                        #write sram
                        #print(len(w_word_stored))

                        temppstr = str(bindigits(row, 8)) + str(bindigits(col, 8)) + str(bindigits(total_ic_cnt*8+ic_cnt, 12))
                        #print("bigword is done:\n%s\n\n" % temppstr)
                        w_word_write_total = temppstr + str(w_word_stored)
                        w_word_write = '{message:>1024{fill}}'.format(message=w_word_write_total, fill='').replace(' ', '0')
                        w_word_stored = ''
                        #print(len(w_word_write))
                        #print(w_word_write)
                        #print ('writing ic: ' + str(total_ic_cnt*8 + ic_cnt))
                        RRAM_word_list.append(w_word_write)
                        #for j in range(0, 4):
                            #w_mem[write_w_num][j].write(w_word_write[512 + (3-j) * 128: 512 + (4-j) * 128] + '\n')
                            #w_mem[write_w_num+1][j].write(w_word_write[(3-j) * 128: (4-j) * 128] + '\n')
                            #w_mem_cnt[j] = w_mem_cnt[j] + 1
                    if(last_word == 1):
                        #print('write_last_word')
                        w_word_write_total = str(bindigits(oa_size, 8)) + str(bindigits(oa_size, 8)) + str(bindigits(ic, 12)) + str(w_word_total)
                        w_word_write = '{message:>1024{fill}}'.format(message=w_word_write_total, fill='').replace(' ', '0')
                        w_word_stored = ''
                        #print(len(w_word_write))
                        #print(w_word_write)
                        #print ('writing ic: ' + str(total_ic_cnt*8 + ic_cnt))
                        RRAM_word_list.append(w_word_write)


RRAM_file = open('RRAM.txt', 'w+')
RRAM_word_list_full = []

sharedmem_file = open('SHARED.txt', 'w+')
sharedmem_word_list_full = []
for item in RRAM_word_list:
    RRAM_file.write(hexify(item) + '\n')
    sharedmem_file.write(hexify(item[0:512]) + '\n')
    sharedmem_file.write(hexify(item[512:1024]) +'\n')

fcwaddr = weights_addr
print("SFC weights start addr (512b): %d (0x%X)" % (fcwaddr,fcwaddr))
for i in range(0, len(RRAM_word_list)): # 2048
    fc_superset = ((fcwaddr >> 9) & 0x3)
    fc_set      = ((fcwaddr >> 11) & 0x7)
    fc_word     =  (fcwaddr & 0x1FF)
    #print("fc_superset: %d fc_set: %d fc_word: %d" % (fc_superset,fc_set,fc_word))
    #print(hexify(RRAM_word_list[i])[128:256])
    unified_memlist[fc_superset][fc_set][3][fc_word] = RRAM_word_list[i][512:640]
    unified_memlist[fc_superset][fc_set][2][fc_word] = RRAM_word_list[i][640:768]
    unified_memlist[fc_superset][fc_set][1][fc_word] = RRAM_word_list[i][768:896]
    unified_memlist[fc_superset][fc_set][0][fc_word] = RRAM_word_list[i][896:1024]
    #print(hexify(unified_memlist[fc_superset][fc_set][0][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][1][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][2][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][3][fc_word]))
    fcwaddr += 1
    fc_superset = ((fcwaddr >> 9) & 0x3)
    fc_set      = ((fcwaddr >> 11) & 0x7)
    fc_word     =  (fcwaddr & 0x1FF)
    #print("fc_superset: %d fc_set: %d fc_word: %d" % (fc_superset,fc_set,fc_word))
    #print(hexify(RRAM_word_list[i])[0:128])
    unified_memlist[fc_superset][fc_set][3][fc_word] = RRAM_word_list[i][0:128]
    unified_memlist[fc_superset][fc_set][2][fc_word] = RRAM_word_list[i][128:256]
    unified_memlist[fc_superset][fc_set][1][fc_word] = RRAM_word_list[i][256:384]
    unified_memlist[fc_superset][fc_set][0][fc_word] = RRAM_word_list[i][384:512]
    #print(hexify(unified_memlist[fc_superset][fc_set][0][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][1][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][2][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][3][fc_word]))
    fcwaddr += 1

print("SFC weights end addr (512b): %d (0x%X)" % (fcwaddr,fcwaddr))


#OA SRAM

big_oa = open('big_oa.mem','w')

oa_mem_cnt=0

oa_word_total = ''
oa_word_cnt = 0

for total_oc_cnt in range(0, int(oc/8)):
    for row in range (0, oa_size):
        for col in range (0, oa_size):
            for oc_cnt in range (0, 8):
                oa_word_total = str(bindigits(oa[total_oc_cnt*8+oc_cnt][row][col], 8)) + str(oa_word_total)
                oa_word_cnt = oa_word_cnt + 1
                if(oa_word_cnt == 64):
                    big_oa.write(hexify(oa_word_total) + '\n')
                    oa_word_total = ''
                    oa_mem_cnt = oa_mem_cnt + 1
                    oa_word_cnt = 0

for rest_addr in range(0, 512-oa_mem_cnt):
    big_oa.write('0' * 128 + '\n')

big_oa.close()


#golden
ia_golden = open('ia.txt','w+') 
for ic_cnt in range (0, ic):
    ia_golden.write('ia channel: [' + str(ic_cnt) + ']\n')
    for row in range (0, ia_size):
        for col in range (0, ia_size):
            ia_golden.write(str(format(ia[ic_cnt][row][col], '4d')) + '\t')
        ia_golden.write('\n')

ia_golden.close()

w_golden = open('weight.txt','w+') 

for ic_cnt in range (0, ic):
    for oc_cnt in range (0, oc):
        for row in range (0, oa_size):
            for col in range (0, oa_size):
                if(sparse_w[oc_cnt][ic_cnt][row][col] != 0):
                    w_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
                    w_golden.write(str(format(sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
                    w_golden.write('\n')

w_golden.close()

oa_golden = open('oa.txt','w+') 
for oc_cnt in range (0, oc):
    oa_golden.write('oa channel: [' + str(oc_cnt) + ']\n')
    for row in range (0, oa_size):
        for col in range (0, oa_size):
            oa_golden.write(str(format(oa[oc_cnt][row][col], '4d')) + '\t')
        oa_golden.write('\n')

oa_golden.close()

oa_original_golden = open('oa_original.txt','w+') 
for oc_cnt in range (0, oc):
    oa_original_golden.write('oa channel: [' + str(oc_cnt) + ']\n')
    for row in range (0, oa_size):
        for col in range (0, oa_size):
            oa_original_golden.write(str(format(oa_original[oc_cnt][row][col], '4d')) + '\t')
        oa_original_golden.write('\n')

oa_original_golden.close()


#================================================
# WRITE ADDRESSES TO NCX_RF.TXT
#================================================

with open('ncx_rf.txt','w') as fd:
    fd.write("0000\n")
    fd.write("%04x\n" % input_data_addr)
    fd.write("%04x\n" % weights_addr)
    for i in range(0,20):
        fd.write("0000\n")
    fd.write("0000")


#================================================
# WRITE UNIFIED MEMLIST TO FILES
#================================================
# open files
unified_files=[]
for i in range(0,unified_supers): #superset
    unified_files.append([])
    for j in range(0,unified_sets): #set
        unified_files[i].append([])
        for k in range(0,unified_banks): #bank
            if(args.byte):
                unified_files[i][j].append(open('unified_sram/in_' + str(i) + '_' + str(j) + '_' + str(k) + '.bytes','w'))
            else:
                unified_files[i][j].append(open('unified_sram/in_' + str(i) + '_' + str(j) + '_' + str(k) + '.mem','w'))


# figure out which banks will be all zeros
memlist_word_valid = np.zeros((unified_supers,unified_sets,unified_banks,512),dtype=np.uint8)
is_unified_bank_all_zero = np.zeros((unified_supers,unified_sets,unified_banks),dtype=np.bool)
last_valid_words = np.zeros((unified_supers,unified_sets,unified_banks))
for i in range(0,unified_supers):
    for j in range(0,unified_sets):
        for k in range(0,unified_banks):
            allzeros = True
            for n in range(0,512):
                if(unified_memlist_valids[i][j][k][n] == 1):
                    allzeros = False
                    memlist_word_valid[i][j][k][n] = 1
                else:
                    memlist_word_valid[i][j][k][n] = 0

            is_unified_bank_all_zero[i][j][k] = allzeros
            if(allzeros):
                last_valid_words[i][j][k] = 0
            else:
                try:
                    vall = np.argwhere(memlist_word_valid[i][j][k]==1)[::-1][0]
                    last_valid_words[i][j][k] = vall
                except(IndexError):
                    print("ERROR in last_valid_word generation")


with open('unified_sram/empty_or_valid.txt', "w") as fd:
    # note i & j are switched because we are following addressing order
    for j in range(0,unified_sets):
        for i in range(0,unified_supers):
            for k in range(0,unified_banks):
                if(is_unified_bank_all_zero[i][j][k]):
                    fd.write("0\n")
                else:
                    fd.write("1\n")


with open('unified_sram/num_valid_per_bank.txt', "w") as fd:
    for j in range(0,unified_sets):
        for i in range(0,unified_supers):
            for k in range(0,unified_banks):
                fd.write("%x\n" % int(np.sum(memlist_word_valid[i][j][k])) )

with open('unified_sram/last_valid_word_in_each_bank.txt', "w") as fd:
        for j in range(0,unified_sets):
            for i in range(0,unified_supers):
                for k in range(0,unified_banks):
                    if(np.sum(memlist_word_valid[i][j][k]) > 0):
                        fd.write("%x\n" % int(last_valid_words[i][j][k] + 1))
                    else:
                        fd.write("%x\n" % int(last_valid_words[i][j][k]))


for i in range(0,unified_supers):
    for j in range(0,unified_sets):
        for k in range(0,unified_banks):

            fd = open('unified_sram/in_' + str(i) + '_' + str(j) + '_' + str(k) + '_valids.txt', 'w')

            for n in range(0,512):
                for x in range(0,16):
                    fd.write("%d\n" % memlist_word_valid[i][j][k][n])

            fd.close()





for i in range(0,unified_supers): #sup
    for j in range(0,unified_sets): #set
        for k in range(0,unified_banks): #bank
            for n in range(0,512): #word
                if(args.byte):
                    hexxx = hexify(unified_memlist[i][j][k][n])
                    for q in range(0,16):
                        unified_files[i][j][k].write("%s" % hexxx[(q*2)+1])
                        unified_files[i][j][k].write("%s\n" % hexxx[q*2])
                else:
                    unified_files[i][j][k].write(hexify(unified_memlist[i][j][k][n]) + '\n')


for i in range(0,unified_supers): #superset
    unified_files.append([])
    for j in range(0,unified_sets): #set
        unified_files[i].append([])
        for k in range(0,unified_banks): #bank
            unified_files[i][j][k].close()



print("\nDONE")
