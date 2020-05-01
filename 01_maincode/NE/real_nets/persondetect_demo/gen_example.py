import numpy as np
from HuffmanCoding_weights import HuffmanCoding
import os
import math
import argparse


parser = argparse.ArgumentParser()
parser.add_argument('-b', '--byte', help='Print 1 byte per line for unified_sram files', action='store_true')
args = parser.parse_args()

####################################################
############      C O M M O N        ###############
####################################################

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

if not os.path.exists("conv1"):
    os.makedirs("conv1")

if not os.path.exists("conv2"):
    os.makedirs("conv2")


np.random.seed(8675309)

weight_wordsize = int(128)
pe_ic = int(8)
pe_oc = int(8)
huff_size = int(15)
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



####################################################
# CONV 1                                           #
####################################################



# input is at addr 0
# these do not need to change per input chunk
layer1_unified_huff_base_addr_128 = int(2560)
layer1_unified_bias_base_addr_128 = int(7168)
layer1_unified_w_base_addr_128    = int(8704)

# params for entire layer1
layer1_ic = int(8)
layer1_oc = int(16)
layer1_true_ic = int(8)
# weights for entire img
conv1_process_kernel_size = int(3)
f_w1=int(7)
f_b1=int(7)
#layer1_w = np.random.randint(-8, high=16, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size), dtype=np.int8)
#layer1_bias = np.random.randint(-4, high=4, size=layer1_oc, dtype=np.int8)
#np.save("weight_files/conv1b.npy", layer1_bias)

layer1_sparse_w = np.zeros((layer1_oc,layer1_ic,conv1_process_kernel_size,conv1_process_kernel_size))
layer1_sparse_w_load = np.load("weight_files/pd_W1_quant.npy")
layer1_bias = np.load("weight_files/pd_b1_quant.npy")
layer1_bias = np.int8(layer1_bias*(2**f_b1))
print(np.shape(layer1_bias))
layer1_bias = np.reshape(layer1_bias,(layer1_oc,))
print(np.shape(layer1_bias))

#np.append(layer1_sparse_w,np.zeros(3,3),axis=1)
for i in range(16):
	for j in range(8):
		if j is 0:
			layer1_sparse_w[i][j] = layer1_sparse_w_load[i][j]*(2**f_w1)
layer1_sparse_w=np.int8(layer1_sparse_w)

# sparsify
#sparse_loc = (np.random.randint(0, high=2, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size)))
#np.save("weight_files/conv1w.npy", layer1_sparse_w)
print("layer1 conv1 w density: " + str( (float(np.count_nonzero(layer1_sparse_w))/float(layer1_ic*layer1_oc*conv1_process_kernel_size*conv1_process_kernel_size))*float(100) ) + "%")

# encode the weights
layer1_weight_list = []
layer1_runlength_list = []
layer1_abs_loc_list = [] 

print("layer1_sparse_w shape: "+str( np.array(layer1_sparse_w).shape ))

pe_oc=int(8)
pe_ic=int(8)

layer1_weight_sanity_check_list = []
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    layer1_weight_sanity_check_list.append([])
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)):
        layer1_weight_sanity_check_list[oc_cnt_base].append([])
        for row in range (0, conv1_process_kernel_size):
            layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base].append([])
            for col in range (0, conv1_process_kernel_size):
                runlength = 0
                layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row].append([])
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):

                        layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col].append(layer1_sparse_w[oc_cnt_base*pe_oc+oc_cnt][ic_cnt_base*pe_ic+ic_cnt][row][col])
                        if(layer1_sparse_w[oc_cnt_base*pe_oc+oc_cnt][ic_cnt_base*pe_ic+ic_cnt][row][col] == 0):
                            if(runlength == weight_wordsize or (oc_cnt == pe_oc-1 and ic_cnt == pe_ic-1)):
                                layer1_weight_list.append(0)
                                layer1_runlength_list.append(runlength)
                                layer1_abs_loc_list.append([oc_cnt_base, ic_cnt_base, row, col])
                                runlength = 1
                            else:
                                runlength = runlength + 1
                        else:
                            layer1_weight_list.append(layer1_sparse_w[oc_cnt_base*pe_oc+oc_cnt][ic_cnt_base*pe_ic+ic_cnt][row][col])
                            layer1_runlength_list.append(runlength)
                            layer1_abs_loc_list.append([oc_cnt_base, ic_cnt_base, row, col])
                            runlength = 1

print("layer1_weight_sanity_check_list shape: "+str(np.array(layer1_weight_sanity_check_list).shape))
layer1_weights_htree          = HuffmanCoding(layer1_weight_list)
layer1_weight_list_coded      = layer1_weights_htree.compress()
layer1_weight_list_decoded    = layer1_weights_htree.decompress(layer1_weight_list_coded)
layer1_weight_codes           = layer1_weights_htree.get_codes()
layer1_weight_table           = layer1_weights_htree.get_code_table()
layer1_runlength_htree        = HuffmanCoding(layer1_runlength_list)
layer1_runlength_list_coded   = layer1_runlength_htree.compress()
layer1_runlength_list_decoded = layer1_runlength_htree.decompress(layer1_runlength_list_coded)
layer1_runlength_codes        = layer1_runlength_htree.get_codes()
layer1_runlength_table        = layer1_runlength_htree.get_code_table()

print ('Weight list decoded properly: {}'.format(layer1_weight_list_decoded == layer1_weight_list))
print ('Runlength list decoded properly: {}'.format(layer1_runlength_list_decoded == layer1_runlength_list))
layer1_weight_mapping_file    = open('conv1/weight_mapping.txt', 'w')
layer1_weight_table_file      = open('conv1/weight_table.txt', 'w')
layer1_weight_raw_file        = open('conv1/weight_list_raw.txt', 'w')
layer1_weight_coded_file      = open('conv1/weight_list_coded.txt', 'w')
layer1_runlength_mapping_file = open('conv1/runlength_mapping.txt', 'w')
layer1_runlength_table_file   = open('conv1/runlength_table.txt', 'w')
layer1_runlength_raw_file     = open('conv1/runlength_list_raw.txt', 'w')
layer1_runlength_coded_file   = open('conv1/runlength_list_coded.txt', 'w')
for item in layer1_weight_list:
  layer1_weight_raw_file.write("%s\n" % item)
for item in layer1_weight_list_coded:
  layer1_weight_coded_file.write("%s\n" % item)
for item in layer1_runlength_list:
  layer1_runlength_raw_file.write("%s\n" % item)
for item in layer1_runlength_list_coded:
  layer1_runlength_coded_file.write("%s\n" % item)
for item in layer1_weight_codes:
    layer1_weight_mapping_file.write(str(item) + ' ' + str(layer1_weight_codes[item]) + '\n')
for subtree in layer1_weight_table:
    for item in subtree:
        if(item ==''):
            layer1_weight_table_file.write('00000000000000' + '\n')
        else:
            layer1_weight_table_file.write(item + '\n')
for item in layer1_runlength_codes:
    layer1_runlength_mapping_file.write(str(item) + ' ' + str(layer1_runlength_codes[item]) + '\n')
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item ==''):
            layer1_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer1_runlength_table_file.write(item + '\n')


layer1_weight_sanity_check_file = open('conv1/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)): 
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer1_weight_sanity_check_file.write(str(format(layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer1_weight_sanity_check_file.write('\n')

i = 0
last_abs_loc = [0, 0, 0, -1]
layer1_CWRAM_word = ''
layer1_CWRAM_word_list = []
layer1_CWRAM_word_list_full = []
while(i < len(layer1_weight_list_coded)):
    if(layer1_abs_loc_list[i] != last_abs_loc and len(layer1_CWRAM_word) == 0):
        layer1_CWRAM_word = str(bindigits(layer1_abs_loc_list[i][0], 9)) + str(bindigits(layer1_abs_loc_list[i][1], 9)) + str(bindigits(layer1_abs_loc_list[i][2], 4)) + str(bindigits(layer1_abs_loc_list[i][3], 4)) + '1'
        last_abs_loc = layer1_abs_loc_list[i]
    elif(layer1_abs_loc_list[i] == last_abs_loc and len(layer1_CWRAM_word) == 0):
        layer1_CWRAM_word = '0'
    elif(layer1_abs_loc_list[i] != last_abs_loc and len(layer1_CWRAM_word) != 0):
        layer1_CWRAM_word = '{message:>128{fill}}'.format(message=layer1_CWRAM_word, fill='').replace(' ', '0')
        layer1_CWRAM_word_list.append(layer1_CWRAM_word)
        layer1_CWRAM_word = ''
    else:
        if(len(layer1_CWRAM_word) + len(layer1_weight_list_coded[i]) + len(layer1_runlength_list_coded[i]) <= weight_wordsize):
            layer1_CWRAM_word = layer1_runlength_list_coded[i][::-1] + layer1_weight_list_coded[i][::-1] + layer1_CWRAM_word
            last_abs_loc = layer1_abs_loc_list[i]
            i = i + 1
            if(len(layer1_CWRAM_word) == weight_wordsize):
                layer1_CWRAM_word_list.append(layer1_CWRAM_word)
                layer1_CWRAM_word = ''
            elif(i == len(layer1_weight_list_coded)):
                layer1_CWRAM_word = '{message:>128{fill}}'.format(message=layer1_CWRAM_word, fill='').replace(' ', '0')
                layer1_CWRAM_word_list.append(layer1_CWRAM_word)
                layer1_CWRAM_word = ''
        else:
            layer1_CWRAM_word = (str(layer1_runlength_list_coded[i])[::-1] + str(layer1_weight_list_coded[i])[::-1])[len(str(layer1_weight_list_coded[i]) + str(layer1_runlength_list_coded[i]))-(weight_wordsize-len(layer1_CWRAM_word)):] + layer1_CWRAM_word
            layer1_CWRAM_word_list.append(layer1_CWRAM_word)
            layer1_CWRAM_word = ''
  
layer1_CWRAM_file = open('conv1/CWRAM.txt', 'w')
for item in layer1_CWRAM_word_list:
  layer1_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer1_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()


layer1_CWRAM_full_file = open('conv1/CWRAM_full.txt', 'w')
for item in layer1_CWRAM_word_list_full:
  layer1_CWRAM_full_file.write("%s\n" % item)





#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer1_unified_w_base_addr_128
print("conv1 weights start at %d (0x%X)" % (cwaddr,cwaddr))
for i in range(0, len(layer1_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer1_CWRAM_word_list_full[i]
    unified_memlist_valids[cwram_superset][cwram_set][cwram_bank][cwram_word] = 1
    cwaddr += 1
print("conv1 weights END at %d (0x%X)" % (cwaddr,cwaddr))
print("conv1 weights SIZE %d (bit)" % ((cwaddr - layer1_unified_w_base_addr_128)*128))
print("conv1 weights len %d (bit)" % (len(layer1_CWRAM_word_list_full)))


#~~~~~~~
# HUFFMAN
#~~~~~~~
huff_w_list=[]
huff_w_list.append("")
huff_slack = str('0'*int(unified_wordsize-(unified_huff_per_word*huff_size)))
n = 0
w = 0
for subtree in layer1_weight_table:
    for item in subtree:
        if(item == ''):
            huff_w_list[w] = str(str('0'*huff_size) + huff_w_list[w])
        else:
            huff_w_list[w] = str(item + huff_w_list[w])

        n += 1
        if(n == unified_huff_per_word):
            huff_w_list[w] = str(huff_slack + huff_w_list[w])
            huff_w_list.append("")
            w += 1
            n = 0

if(n != 0):
    # last word couldnt pack a full 8
    print("!WARNING! Last Item size w table: {}".format(n))
    layer1_huffman_w_last_item_size = n
    
    huff_w_list[w] = str( str(str('0'*huff_size)*(unified_huff_per_word-n)) + huff_w_list[w] )
    huff_w_list[w] = str(huff_slack + huff_w_list[w])
    layer1_huffman_w_number_128_words = w+1
else:
    layer1_huffman_w_last_item_size = unified_huff_per_word
    layer1_huffman_w_number_128_words = w

print("conv1 huff W num words: %d" % layer1_huffman_w_number_128_words)
print("conv1 huff W SIZE %d (bit)" % (layer1_huffman_w_number_128_words*128))


huff_loc_list=[]
huff_loc_list.append("")
n = 0
w = 0
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item == ''):
            huff_loc_list[w] = str(str('0'*huff_size) + huff_loc_list[w])
        else:
            huff_loc_list[w] = str(item + huff_loc_list[w])

        n += 1
        if(n == unified_huff_per_word):
            huff_loc_list[w] = str(huff_slack + huff_loc_list[w])
            huff_loc_list.append("")
            w += 1
            n = 0

if(n != 0):
    print("!WARNING! Last Item size loc table: {}".format(n))
    layer1_huffman_loc_last_item_size = n
    
    huff_loc_list[w] = str( str(str('0'*huff_size)*(unified_huff_per_word-n)) + huff_loc_list[w] )
    huff_loc_list[w] = str(huff_slack + huff_loc_list[w])
    layer1_huffman_loc_number_128_words = w+1
else:
    layer1_huffman_loc_last_item_size = unified_huff_per_word
    layer1_huffman_loc_number_128_words = w

print("conv1 huff LOC num words: %d" % layer1_huffman_loc_number_128_words)
print("conv1 huff LOC SIZE %d (bit)" % (layer1_huffman_loc_number_128_words*128))


huffaddr = layer1_unified_huff_base_addr_128
print("Starting addr for huff w table: %d (0x%X)" % (huffaddr,huffaddr))
for i in range(0, layer1_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    unified_memlist_valids[huff_superset][huff_set][huff_bank][huff_word] = 1
    huffaddr += 1

print("Ending addr for huff w table: %d (0x%X)" % (huffaddr,huffaddr))
print("Starting addr for huff loc table: %d (0x%X)" % (huffaddr,huffaddr))
for i in range(0, layer1_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    unified_memlist_valids[huff_superset][huff_set][huff_bank][huff_word] = 1
    huffaddr += 1

print("Ending addr for huff loc table: %d (0x%X)" % (huffaddr,huffaddr))

#~~~~~~~
# BIAS
#~~~~~~~
bias_memlist=[]
for oc_cnt_base in range(0, int((layer1_oc/pe_oc)/2)): # there are 16 biases/word, not 8
    BRAM_word = ''
    for oc_cnt in range(0, pe_oc*2): # 8
        BRAM_word = str(bindigits(layer1_bias[oc_cnt_base*(pe_oc*2)+oc_cnt], 8)) + BRAM_word
    bias_memlist.append(BRAM_word)

biaddr = layer1_unified_bias_base_addr_128
print("Bias start addr: %d (0x%X)" % (biaddr,biaddr))
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    unified_memlist_valids[bias_superset][bias_set][bias_bank][bias_word] = 1
    biaddr += 1

print("Bias end addr: %d (0x%X)\n" % (biaddr,biaddr))
print("Bias SIZE    : %d (bits)\n" % ((biaddr-layer1_unified_bias_base_addr_128)*128))

# easy to read bias file
bias_file = open('conv1/bias.txt', 'w')
for i in range(0, layer1_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer1_bias[i]) + '\n')
bias_file.close()


weight_golden = open('conv1/weight.txt','w') 
for oc_cnt in range (0, layer1_oc):
    for ic_cnt in range (0, layer1_ic):
        weight_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                weight_golden.write(str(format(layer1_sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
            weight_golden.write('\n')

weight_golden.close()


####################################################
# CONV 2                                           #
####################################################

# input is at addr 0
# these do not need to change per input chunk
layer2_unified_huff_base_addr_128 = int(10240)
layer2_unified_bias_base_addr_128 = int(11776)
layer2_unified_w_base_addr_128    = int(12288)

# params for entire layer2
layer2_ic = int(16)
layer2_oc = int(32)
layer2_true_ic = int(16)
f_b2 = int(6)
f_w2 = int(7)
# weights for entire img
conv2_process_kernel_size = int(3)
#layer2_w = np.random.randint(-8, high=16, size=(layer2_oc, layer2_ic, conv2_process_kernel_size, conv2_process_kernel_size),dtype=np.int8)
#layer2_bias = np.random.randint(-4, high=4, size=layer2_oc, dtype=np.int8)
#np.save("weight_files/conv2b.npy", layer2_bias)
layer2_sparse_w = np.load("weight_files/pd_W2_quant.npy")
layer2_bias = np.load("weight_files/pd_b2_quant.npy")

layer2_bias = np.int8(layer2_bias*(2**f_b2))
layer2_bias = np.reshape(layer2_bias,(layer2_oc,))
layer2_sparse_w = np.int8(layer2_sparse_w*(2**f_w2))

# sparsify
#sparse_loc = (np.random.randint(0, high=2, size=(layer2_oc, layer2_ic, conv2_process_kernel_size, conv2_process_kernel_size)))
#layer2_sparse_w = np.int8((np.multiply(layer2_w, sparse_loc)))
#np.save("weight_files/conv2w.npy", layer2_sparse_w)

print("layer2 conv2 w density: " + str( (float(np.count_nonzero(layer2_sparse_w))/float(layer2_ic*layer2_oc*conv2_process_kernel_size*conv2_process_kernel_size))*float(100) ) + "%")

# encode the weights
layer2_weight_list = []
layer2_runlength_list = []
layer2_abs_loc_list = [] 

print("layer2_sparse_w shape: "+str( np.array(layer2_sparse_w).shape ))

pe_oc=int(8)
pe_ic=int(8)

layer2_weight_sanity_check_list = []
for oc_cnt_base in range (0, int(layer2_oc/pe_oc)): # 4
    layer2_weight_sanity_check_list.append([])
    for ic_cnt_base in range (0, int(layer2_ic/pe_ic)): # 2
        layer2_weight_sanity_check_list[oc_cnt_base].append([])
        for row in range (0, conv2_process_kernel_size): # 3
            layer2_weight_sanity_check_list[oc_cnt_base][ic_cnt_base].append([])
            for col in range (0, conv2_process_kernel_size): # 3
                runlength = 0
                layer2_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row].append([])
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer2_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col].append(layer2_sparse_w[oc_cnt_base*pe_oc+oc_cnt][ic_cnt_base*pe_ic+ic_cnt][row][col])
                        if(layer2_sparse_w[oc_cnt_base*pe_oc+oc_cnt][ic_cnt_base*pe_ic+ic_cnt][row][col] == 0):
                            if(runlength == weight_wordsize or (oc_cnt == pe_oc-1 and ic_cnt == pe_ic-1)):
                                layer2_weight_list.append(0)
                                layer2_runlength_list.append(runlength)
                                layer2_abs_loc_list.append([oc_cnt_base, ic_cnt_base, row, col])
                                runlength = 1
                            else:
                                runlength = runlength + 1
                        else:
                            layer2_weight_list.append(layer2_sparse_w[oc_cnt_base*pe_oc+oc_cnt][ic_cnt_base*pe_ic+ic_cnt][row][col])
                            layer2_runlength_list.append(runlength)
                            layer2_abs_loc_list.append([oc_cnt_base, ic_cnt_base, row, col])
                            runlength = 1

print("layer2_weight_sanity_check_list shape: "+str(np.array(layer2_weight_sanity_check_list).shape))
layer2_weights_htree          = HuffmanCoding(layer2_weight_list)
layer2_weight_list_coded      = layer2_weights_htree.compress()
layer2_weight_list_decoded    = layer2_weights_htree.decompress(layer2_weight_list_coded)
layer2_weight_codes           = layer2_weights_htree.get_codes()
layer2_weight_table           = layer2_weights_htree.get_code_table()
layer2_runlength_htree        = HuffmanCoding(layer2_runlength_list)
layer2_runlength_list_coded   = layer2_runlength_htree.compress()
layer2_runlength_list_decoded = layer2_runlength_htree.decompress(layer2_runlength_list_coded)
layer2_runlength_codes        = layer2_runlength_htree.get_codes()
layer2_runlength_table        = layer2_runlength_htree.get_code_table()

print ('Weight list decoded properly: {}'.format(layer2_weight_list_decoded == layer2_weight_list))
print ('Runlength list decoded properly: {}'.format(layer2_runlength_list_decoded == layer2_runlength_list))

print("layer2_weight_list.shape: ",end='')
print(np.array(layer2_weight_list).shape)
layer2_weight_mapping_file    = open('conv2/weight_mapping.txt', 'w')
layer2_weight_table_file      = open('conv2/weight_table.txt', 'w')
layer2_weight_raw_file        = open('conv2/weight_list_raw.txt', 'w')
layer2_weight_coded_file      = open('conv2/weight_list_coded.txt', 'w')
layer2_runlength_mapping_file = open('conv2/runlength_mapping.txt', 'w')
layer2_runlength_table_file   = open('conv2/runlength_table.txt', 'w')
layer2_runlength_raw_file     = open('conv2/runlength_list_raw.txt', 'w')
layer2_runlength_coded_file   = open('conv2/runlength_list_coded.txt', 'w')
for item in layer2_weight_list:
  layer2_weight_raw_file.write("%s\n" % item)
for item in layer2_weight_list_coded:
  layer2_weight_coded_file.write("%s\n" % item)
for item in layer2_runlength_list:
  layer2_runlength_raw_file.write("%s\n" % item)
for item in layer2_runlength_list_coded:
  layer2_runlength_coded_file.write("%s\n" % item)
for item in layer2_weight_codes:
    layer2_weight_mapping_file.write(str(item) + ' ' + str(layer2_weight_codes[item]) + '\n')
for subtree in layer2_weight_table:
    for item in subtree:
        if(item ==''):
            layer2_weight_table_file.write('00000000000000' + '\n')
        else:
            layer2_weight_table_file.write(item + '\n')
for item in layer2_runlength_codes:
    layer2_runlength_mapping_file.write(str(item) + ' ' + str(layer2_runlength_codes[item]) + '\n')
for subtree in layer2_runlength_table:
    for item in subtree:
        if(item ==''):
            layer2_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer2_runlength_table_file.write(item + '\n')


layer2_weight_sanity_check_file = open('conv2/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer2_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer2_ic/pe_ic)): 
        for row in range (0, conv2_process_kernel_size):
            for col in range (0, conv2_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer2_weight_sanity_check_file.write(str(format(layer2_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer2_weight_sanity_check_file.write('\n')




i = 0
last_abs_loc = [0, 0, 0, -1]
layer2_CWRAM_word = ''
layer2_CWRAM_word_list = []
layer2_CWRAM_word_list_full = []
while(i < len(layer2_weight_list_coded)):
    if(layer2_abs_loc_list[i] != last_abs_loc and len(layer2_CWRAM_word) == 0):
        layer2_CWRAM_word = str(bindigits(layer2_abs_loc_list[i][0], 9)) + str(bindigits(layer2_abs_loc_list[i][1], 9)) + str(bindigits(layer2_abs_loc_list[i][2], 4)) + str(bindigits(layer2_abs_loc_list[i][3], 4)) + '1'
        last_abs_loc = layer2_abs_loc_list[i]
    elif(layer2_abs_loc_list[i] == last_abs_loc and len(layer2_CWRAM_word) == 0):
        layer2_CWRAM_word = '0'
    elif(layer2_abs_loc_list[i] != last_abs_loc and len(layer2_CWRAM_word) != 0):
        layer2_CWRAM_word = '{message:>128{fill}}'.format(message=layer2_CWRAM_word, fill='').replace(' ', '0')
        layer2_CWRAM_word_list.append(layer2_CWRAM_word)
        layer2_CWRAM_word = ''
    else:
        if(len(layer2_CWRAM_word) + len(layer2_weight_list_coded[i]) + len(layer2_runlength_list_coded[i]) <= weight_wordsize):
            layer2_CWRAM_word = layer2_runlength_list_coded[i][::-1] + layer2_weight_list_coded[i][::-1] + layer2_CWRAM_word
            last_abs_loc = layer2_abs_loc_list[i]
            i = i + 1
            if(len(layer2_CWRAM_word) == weight_wordsize):
                layer2_CWRAM_word_list.append(layer2_CWRAM_word)
                layer2_CWRAM_word = ''
            elif(i == len(layer2_weight_list_coded)):
                layer2_CWRAM_word = '{message:>128{fill}}'.format(message=layer2_CWRAM_word, fill='').replace(' ', '0')
                layer2_CWRAM_word_list.append(layer2_CWRAM_word)
                layer2_CWRAM_word = ''
        else:
            layer2_CWRAM_word = (str(layer2_runlength_list_coded[i])[::-1] + str(layer2_weight_list_coded[i])[::-1])[len(str(layer2_weight_list_coded[i]) + str(layer2_runlength_list_coded[i]))-(weight_wordsize-len(layer2_CWRAM_word)):] + layer2_CWRAM_word
            layer2_CWRAM_word_list.append(layer2_CWRAM_word)
            layer2_CWRAM_word = ''
  
layer2_CWRAM_file = open('conv2/CWRAM.txt', 'w')
for item in layer2_CWRAM_word_list:
  layer2_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer2_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()


layer2_CWRAM_full_file = open('conv2/CWRAM_full.txt', 'w')
for item in layer2_CWRAM_word_list_full:
  layer2_CWRAM_full_file.write("%s\n" % item)




#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer2_unified_w_base_addr_128
print("conv2 weights start at %d (0x%X)" % (cwaddr,cwaddr))
for i in range(0, len(layer2_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer2_CWRAM_word_list_full[i]
    unified_memlist_valids[cwram_superset][cwram_set][cwram_bank][cwram_word] = 1
    cwaddr += 1
print("conv2 weights END at %d (0x%X)" % (cwaddr,cwaddr))
print("conv1 weights SIZE %d (bit)" % ((cwaddr - layer2_unified_w_base_addr_128)*128))

#~~~~~~~
# HUFFMAN
#~~~~~~~
huff_w_list=[]
huff_w_list.append("")
huff_slack = str('0'*int(unified_wordsize-(unified_huff_per_word*huff_size)))
n = 0
w = 0
for subtree in layer2_weight_table:
    for item in subtree:
        if(item == ''):
            huff_w_list[w] = str(str('0'*huff_size) + huff_w_list[w])
        else:
            huff_w_list[w] = str(item + huff_w_list[w])

        n += 1
        if(n == unified_huff_per_word):
            huff_w_list[w] = str(huff_slack + huff_w_list[w])
            huff_w_list.append("")
            w += 1
            n = 0

if(n != 0):
    # last word couldnt pack a full 8
    print("!WARNING! Last Item size w table: {}".format(n))
    layer2_huffman_w_last_item_size = n
    
    huff_w_list[w] = str( str(str('0'*huff_size)*(unified_huff_per_word-n)) + huff_w_list[w] )
    huff_w_list[w] = str(huff_slack + huff_w_list[w])
    layer2_huffman_w_number_128_words = w+1
else:
    layer2_huffman_w_last_item_size = unified_huff_per_word
    layer2_huffman_w_number_128_words = w

print("conv2 huff W num words: %d" % layer2_huffman_w_number_128_words)
print("conv1 huff W SIZE %d (bit)" % (layer2_huffman_w_number_128_words*128))

huff_loc_list=[]
huff_loc_list.append("")
n = 0
w = 0
for subtree in layer2_runlength_table:
    for item in subtree:
        if(item == ''):
            huff_loc_list[w] = str(str('0'*huff_size) + huff_loc_list[w])
        else:
            huff_loc_list[w] = str(item + huff_loc_list[w])

        n += 1
        if(n == unified_huff_per_word):
            huff_loc_list[w] = str(huff_slack + huff_loc_list[w])
            huff_loc_list.append("")
            w += 1
            n = 0

if(n != 0):
    print("!WARNING! Last Item size loc table: {}".format(n))
    layer2_huffman_loc_last_item_size = n
    
    huff_loc_list[w] = str( str(str('0'*huff_size)*(unified_huff_per_word-n)) + huff_loc_list[w] )
    huff_loc_list[w] = str(huff_slack + huff_loc_list[w])
    layer2_huffman_loc_number_128_words = w+1
else:
    layer2_huffman_loc_last_item_size = unified_huff_per_word
    layer2_huffman_loc_number_128_words = w

print("conv2 huff LOC num words: %d" % layer2_huffman_loc_number_128_words)
print("conv1 huff LOC SIZE %d (bit)" % (layer2_huffman_loc_number_128_words*128))


huffaddr = layer2_unified_huff_base_addr_128
print("Starting addr for huff w table: %d (0x%X)" % (huffaddr,huffaddr))
for i in range(0, layer2_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    unified_memlist_valids[huff_superset][huff_set][huff_bank][huff_word] = 1
    huffaddr += 1

print("Ending addr for huff w table: %d (0x%X)" % (huffaddr,huffaddr))
print("Starting addr for huff loc table: %d (0x%X)" % (huffaddr,huffaddr))
for i in range(0, layer2_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    unified_memlist_valids[huff_superset][huff_set][huff_bank][huff_word] = 1
    huffaddr += 1

print("Ending addr for huff loc table: %d (0x%X)" % (huffaddr,huffaddr))

#~~~~~~~
# BIAS
#~~~~~~~
bias_memlist=[]
for oc_cnt_base in range(0, int((layer2_oc/pe_oc)/2)): # there are 16 biases/word, not 8
    BRAM_word = ''
    for oc_cnt in range(0, pe_oc*2): # 8
        BRAM_word = str(bindigits(layer2_bias[oc_cnt_base*(pe_oc*2)+oc_cnt], 8)) + BRAM_word
    bias_memlist.append(BRAM_word)

biaddr = layer2_unified_bias_base_addr_128
print("Bias start addr: %d (0x%X)" % (biaddr,biaddr))
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    unified_memlist_valids[bias_superset][bias_set][bias_bank][bias_word] = 1
    biaddr += 1

print("Bias end addr: %d (0x%X)\n" % (biaddr,biaddr))
print("Bias SIZE    : %d (bits)\n" % ((biaddr-layer2_unified_bias_base_addr_128)*128))

# easy to read bias file
bias_file = open('conv2/bias.txt', 'w')
for i in range(0, layer2_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer2_bias[i]) + '\n')
bias_file.close()


weight_golden = open('conv2/weight.txt','w') 
for oc_cnt in range (0, layer2_oc):
    for ic_cnt in range (0, layer2_ic):
        weight_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
        for row in range (0, conv2_process_kernel_size):
            for col in range (0, conv2_process_kernel_size):
                weight_golden.write(str(format(layer2_sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
            weight_golden.write('\n')

weight_golden.close()





##########################################################################################


fc1_w = np.random.randint(low=-4, high=16, size=(8,8,32,64))
fc1_w[:,5:,:,:] = 0
fc1_b = np.random.randint(low=-4, high=10, size=(64,))
fc2_w = np.random.randint(low=-4, high=16, size=(8,8,8,2)) # FC2 organzied as full 8x8 but 1 channel
fc2_w[:,:,1:,:] = 0
fc2_b = np.random.randint(low=-4, high=10, size=(2,))
#
#
#np.save("weight_files/fc1w.npy", fc1_w)
#np.save("weight_files/fc1b.npy", fc1_b)
#np.save("weight_files/fc2w.npy", fc2_w)
#np.save("weight_files/fc2b.npy", fc2_b)
#fc1_w = np.load("weight_files/pd_W3_quant.npy")
#fc1_b = np.load("weight_files/pd_b3_quant.npy")
#fc2_w = np.load("weight_files/pd_W4_quant.npy")
#fc2_b = np.load("weight_files/pd_b4_quant.npy")
fc1_w_load = np.load("weight_files/pd_W3_quant.npy")
fc1_b = np.load("weight_files/pd_b3_quant.npy")
fc2_w_load = np.load("weight_files/pd_W4_quant.npy")
fc2_b = np.load("weight_files/pd_b4_quant.npy")

cnt = 0
for i in range(8):
	for j in range(8):
		if j<5:
			fc1_w[i][j] = fc1_w_load[i][j]
		else :
			for m in range(32):
				for l in range(64):
					fc1_w[i][j] = fc1_w_load[l][cnt]
					cnt+=1
for i in range(8):
	for j in range(8):
		if j<1:
			fc2_w[i][j] = fc2_w_load[i][j]

fc1_w=np.int8(fc1_w*(2**7))
fc1_b=np.int8(fc1_b*(2**2))
fc2_w=np.int8(fc2_w*(2**6))
fc2_b=np.int8(fc2_b*(2**7))

fc1_base_w_addr_512 = int(7680)
fc1_base_b_addr_128 = int(28672)

fc2_base_w_addr_512 = int(9728)
fc2_base_b_addr_128 = int(29184)

wwordlist = []
for i in range(0,4):
    wwordlist.append([])

wword_total = ''
wword_cnt = 0


for filt in range(0,64):
    for chan_base in range(0,4):
        for row in range(0,8):
            for col in range(0,8):
                for chan in range(chan_base*8, (chan_base+1)*8):
                    wword_total = str(bindigits(fc1_w[row][col][chan][filt],8)) + str(wword_total)
                    wword_cnt += 1
                    for bank in range(0,4):
                        if(wword_cnt == 16*(bank+1)):
                            wwordlist[bank].append(wword_total)
                            wword_total = ''
                            if(bank == 3):
                                wword_cnt = 0


# FC1
fcwaddr = fc1_base_w_addr_512
print("FC1 weights start at (512b): %d (0x%X)" % (fcwaddr,fcwaddr))
for i in range(0, len(wwordlist[0])): # 2048
    for j in range(0, 4): # 4 banks
        fc_superset = ((fcwaddr >> 9) & 0x3)
        fc_set      = ((fcwaddr >> 11) & 0x7)
        fc_word     =  (fcwaddr & 0x1FF)
        unified_memlist[fc_superset][fc_set][j][fc_word] = wwordlist[j][i]
        unified_memlist_valids[fc_superset][fc_set][j][fc_word] = 1
    fcwaddr += 1

print("FC1 weights end at (512b):   %d (0x%X)" % (fcwaddr,fcwaddr))

# now we have bias_memlist, time to write
bias_memlist=[]
for oc_cnt_base in range(0, int((64/8)/2)): # there are 16 biases/word, not 8
    BRAM_word = ''
    for oc_cnt in range(0, pe_oc*2): # 8
        BRAM_word = str(bindigits(fc1_b[oc_cnt_base*(pe_oc*2)+oc_cnt], 8)) + BRAM_word
    bias_memlist.append(BRAM_word)

# also add in fc2
BRAM_word = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" + str(bindigits(fc2_b[1],8)) + str(bindigits(fc2_b[0],8))
bias_memlist.append(BRAM_word)

# now actual write biases for FC1 & FC2
biaddr = fc1_base_b_addr_128
print("FC1 bias start at (128b): %d (0x%X)" % (biaddr,biaddr))
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1

print("FC1 bias end at (128b):   %d (0x%X)" % (biaddr,biaddr))

# FC2
wwordlist = []
for i in range(0, 4):
    wwordlist.append([])

wword_total = ''
wword_cnt = 0
for filt in range(0, 2):
    for row in range(0, 8):
        for col in range(0, 8):
            for chan in range(0, 8):
                wword_total = str(bindigits(fc2_w[row][col][chan][filt],8)) + str(wword_total)
                wword_cnt += 1
                for bank in range(0,4):
                    if wword_cnt == 16*(bank+1):
                        wwordlist[bank].append(wword_total)
                        wword_total = ''
                        if bank == 3:
                            wword_cnt = 0


fcwaddr = fc2_base_w_addr_512
print("FC2 weights start at (512b): %d (0x%X)" % (fcwaddr,fcwaddr))
for i in range(0, len(wwordlist[0])): # 2048
    for j in range(0, 4): # 4 banks
        fc_superset = ((fcwaddr >> 9) & 0x3)
        fc_set      = ((fcwaddr >> 11) & 0x7)
        fc_word     =  (fcwaddr & 0x1FF)
        unified_memlist[fc_superset][fc_set][j][fc_word] = wwordlist[j][i]
        unified_memlist_valids[fc_superset][fc_set][j][fc_word] = 1
    fcwaddr += 1

print("FC2 weights end at (512b):   %d (0x%X)" % (fcwaddr,fcwaddr))





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
