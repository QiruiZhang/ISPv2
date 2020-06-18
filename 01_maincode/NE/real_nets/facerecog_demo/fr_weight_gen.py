import numpy as np
from HuffmanCoding_weights import HuffmanCoding
import os
import math

####################################################
############      C O M M O N        ###############
####################################################

def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)

def hexify(binstring):
    hstr = '%0*X' % ((len(binstring) + 3) // 4, int(binstring, 2))
    return hstr

# make dirs if they do not yet exist
if not os.path.exists("unified_sram"): os.makedirs("unified_sram")
if not os.path.exists("weight_files"): os.makedirs("weight_files")
if not os.path.exists("weight_files/conv1"): os.makedirs("weight_files/conv1")
if not os.path.exists("weight_files/conv2"): os.makedirs("weight_files/conv2")
if not os.path.exists("weight_files/conv3"): os.makedirs("weight_files/conv3")
if not os.path.exists("weight_files/conv4"): os.makedirs("weight_files/conv4")
if not os.path.exists("weight_files/sparse_fc1"): os.makedirs("weight_files/sparse_fc1")
if not os.path.exists("weight_files/dense_fc2"): os.makedirs("weight_files/dense_fc2")

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

####################################################
# CONV 1                                           #
####################################################

# these do not need to change per input chunk
layer1_unified_huff_base_addr_128 = int(16342)
layer1_unified_bias_base_addr_128 = int(16368)
layer1_unified_w_base_addr_128    = int(16000)

# params for entire layer1
layer1_ic = int(8)
layer1_oc = int(48)
layer1_true_ic = int(8)
# weights for entire img
conv1_process_kernel_size = int(5)
f_w1=int(4)
f_b1=int(3)
layer1_w = np.random.randint(-8, high=16, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size), dtype=np.int8)
layer1_bias = np.random.randint(-4, high=4, size=layer1_oc, dtype=np.int8)
np.save("weight_files/conv1/conv1b.npy", layer1_bias)

# sparsify
sparse_loc = (np.random.randint(0, high=2, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size)))
layer1_sparse_w = np.int8((np.multiply(layer1_w, sparse_loc)))
np.save("weight_files/conv1/conv1w.npy", layer1_sparse_w)

############################
layer1_sparse_w = np.zeros((layer1_oc,layer1_ic,conv1_process_kernel_size,conv1_process_kernel_size))
layer1_sparse_w_load = np.load("weight_files/fr_W1_quant.npy")
layer1_bias = np.load("weight_files/fr_b1_quant.npy")
layer1_bias = np.int8(layer1_bias*(2**f_b1))
print(np.shape(layer1_bias))
layer1_bias = np.reshape(layer1_bias,(layer1_oc,))
print(np.shape(layer1_bias))
for i in range(48):
	for j in range(8):
		if j is 0:
			layer1_sparse_w[i][j] = layer1_sparse_w_load[i][j]*(2**f_w1)
layer1_sparse_w=np.int8(layer1_sparse_w)
#########################

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
layer1_weight_mapping_file    = open('weight_files/conv1/weight_mapping.txt', 'w')
layer1_weight_table_file      = open('weight_files/conv1/weight_table.txt', 'w')
layer1_weight_raw_file        = open('weight_files/conv1/weight_list_raw.txt', 'w')
layer1_weight_coded_file      = open('weight_files/conv1/weight_list_coded.txt', 'w')
layer1_runlength_mapping_file = open('weight_files/conv1/runlength_mapping.txt', 'w')
layer1_runlength_table_file   = open('weight_files/conv1/runlength_table.txt', 'w')
layer1_runlength_raw_file     = open('weight_files/conv1/runlength_list_raw.txt', 'w')
layer1_runlength_coded_file   = open('weight_files/conv1/runlength_list_coded.txt', 'w')
for item in layer1_weight_list:
  layer1_weight_raw_file.write("%s\n" % item)
layer1_weight_raw_file.close()
for item in layer1_weight_list_coded:
  layer1_weight_coded_file.write("%s\n" % item)
layer1_weight_coded_file.close()
for item in layer1_runlength_list:
  layer1_runlength_raw_file.write("%s\n" % item)
layer1_runlength_raw_file.close()
for item in layer1_runlength_list_coded:
  layer1_runlength_coded_file.write("%s\n" % item)
layer1_runlength_coded_file.close()
for item in layer1_weight_codes:
    layer1_weight_mapping_file.write(str(item) + ' ' + str(layer1_weight_codes[item]) + '\n')
layer1_weight_mapping_file.close()
for subtree in layer1_weight_table:
    for item in subtree:
        if(item ==''):
            layer1_weight_table_file.write('00000000000000' + '\n')
        else:
            layer1_weight_table_file.write(item + '\n')
layer1_weight_table_file.close()
for item in layer1_runlength_codes:
    layer1_runlength_mapping_file.write(str(item) + ' ' + str(layer1_runlength_codes[item]) + '\n')
layer1_runlength_mapping_file.close()
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item ==''):
            layer1_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer1_runlength_table_file.write(item + '\n')
layer1_runlength_table_file.close()

layer1_weight_sanity_check_file = open('weight_files/conv1/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)): 
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer1_weight_sanity_check_file.write(str(format(layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer1_weight_sanity_check_file.write('\n')
layer1_weight_sanity_check_file.close()

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
  
layer1_CWRAM_file = open('weight_files/conv1/CWRAM.txt', 'w')
for item in layer1_CWRAM_word_list:
  layer1_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer1_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()
layer1_CWRAM_file.close()

layer1_CWRAM_full_file = open('weight_files/conv1/CWRAM_full.txt', 'w')
for item in layer1_CWRAM_word_list_full:
  layer1_CWRAM_full_file.write("%s\n" % item)
layer1_CWRAM_full_file.close()

#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer1_unified_w_base_addr_128
print("conv1 weights start at %d" % cwaddr)
for i in range(0, len(layer1_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer1_CWRAM_word_list_full[i]
    cwaddr += 1
print("conv1 weights END at %d" % cwaddr)

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

huffaddr = layer1_unified_huff_base_addr_128
print("Starting addr for huff w table: %d" % huffaddr)
for i in range(0, layer1_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    huffaddr += 1

print("Starting addr for huff loc table: %d" % huffaddr)
for i in range(0, layer1_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    huffaddr += 1


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
print("Starting addr for bias: %d" % biaddr)
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1

print("Bias end addr: %d\n" % biaddr)

# easy to read bias file
bias_file = open('weight_files/conv1/bias.txt', 'w')
for i in range(0, layer1_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer1_bias[i]) + '\n')
bias_file.close()


weight_golden = open('weight_files/conv1/weight.txt','w') 
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

# these do not need to change per input chunk
layer1_unified_huff_base_addr_128 = int(17845)
layer1_unified_bias_base_addr_128 = int(17871)
layer1_unified_w_base_addr_128    = int(16400)

# params for entire layer1
layer1_ic = int(48)
layer1_oc = int(96)
layer1_true_ic = int(48)
f_b1 = int(4)
f_w1 = int(7)
# weights for entire img
conv1_process_kernel_size = int(3)
layer1_w = np.random.randint(-8, high=16, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size), dtype=np.int8)
layer1_bias = np.random.randint(-4, high=4, size=layer1_oc, dtype=np.int8)
np.save("weight_files/conv2/conv2b.npy", layer1_bias)

# sparsify
sparse_loc = (np.random.randint(0, high=2, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size)))
layer1_sparse_w = np.int8((np.multiply(layer1_w, sparse_loc)))
np.save("weight_files/conv2/conv2w.npy", layer1_sparse_w)

##########################################################
layer1_sparse_w = np.load("weight_files/fr_W2_quant.npy")
layer1_bias = np.load("weight_files/fr_b2_quant.npy")

layer1_bias = np.int8(layer1_bias*(2**f_b1))
layer1_bias = np.reshape(layer1_bias,(layer1_oc,))
layer1_sparse_w = np.int8(layer1_sparse_w*(2**f_w1))
##########################################################

print("layer2 conv2 w density: " + str( (float(np.count_nonzero(layer1_sparse_w))/float(layer1_ic*layer1_oc*conv1_process_kernel_size*conv1_process_kernel_size))*float(100) ) + "%")

# encode the weights
layer1_weight_list = []
layer1_runlength_list = []
layer1_abs_loc_list = [] 

print("layer2_sparse_w shape: "+str( np.array(layer1_sparse_w).shape ))

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

print("layer2_weight_sanity_check_list shape: "+str(np.array(layer1_weight_sanity_check_list).shape))
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
layer1_weight_mapping_file    = open('weight_files/conv2/weight_mapping.txt', 'w')
layer1_weight_table_file      = open('weight_files/conv2/weight_table.txt', 'w')
layer1_weight_raw_file        = open('weight_files/conv2/weight_list_raw.txt', 'w')
layer1_weight_coded_file      = open('weight_files/conv2/weight_list_coded.txt', 'w')
layer1_runlength_mapping_file = open('weight_files/conv2/runlength_mapping.txt', 'w')
layer1_runlength_table_file   = open('weight_files/conv2/runlength_table.txt', 'w')
layer1_runlength_raw_file     = open('weight_files/conv2/runlength_list_raw.txt', 'w')
layer1_runlength_coded_file   = open('weight_files/conv2/runlength_list_coded.txt', 'w')
for item in layer1_weight_list:
  layer1_weight_raw_file.write("%s\n" % item)
layer1_weight_raw_file.close()
for item in layer1_weight_list_coded:
  layer1_weight_coded_file.write("%s\n" % item)
layer1_weight_coded_file.close()
for item in layer1_runlength_list:
  layer1_runlength_raw_file.write("%s\n" % item)
layer1_runlength_raw_file.close()
for item in layer1_runlength_list_coded:
  layer1_runlength_coded_file.write("%s\n" % item)
layer1_runlength_coded_file.close()
for item in layer1_weight_codes:
    layer1_weight_mapping_file.write(str(item) + ' ' + str(layer1_weight_codes[item]) + '\n')
layer1_weight_mapping_file.close()
for subtree in layer1_weight_table:
    for item in subtree:
        if(item ==''):
            layer1_weight_table_file.write('00000000000000' + '\n')
        else:
            layer1_weight_table_file.write(item + '\n')
layer1_weight_table_file.close()
for item in layer1_runlength_codes:
    layer1_runlength_mapping_file.write(str(item) + ' ' + str(layer1_runlength_codes[item]) + '\n')
layer1_runlength_mapping_file.close()
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item ==''):
            layer1_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer1_runlength_table_file.write(item + '\n')
layer1_runlength_table_file.close()

layer1_weight_sanity_check_file = open('weight_files/conv2/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)): 
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer1_weight_sanity_check_file.write(str(format(layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer1_weight_sanity_check_file.write('\n')
layer1_weight_sanity_check_file.close()

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
  
layer1_CWRAM_file = open('weight_files/conv2/CWRAM.txt', 'w')
for item in layer1_CWRAM_word_list:
  layer1_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer1_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()
layer1_CWRAM_file.close()

layer1_CWRAM_full_file = open('weight_files/conv2/CWRAM_full.txt', 'w')
for item in layer1_CWRAM_word_list_full:
  layer1_CWRAM_full_file.write("%s\n" % item)
layer1_CWRAM_full_file.close()

#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer1_unified_w_base_addr_128
print("conv2 weights start at %d" % cwaddr)
for i in range(0, len(layer1_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer1_CWRAM_word_list_full[i]
    cwaddr += 1
print("conv2 weights END at %d" % cwaddr)

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

print("conv2 huff W num words: %d" % layer1_huffman_w_number_128_words)


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

print("conv2 huff LOC num words: %d" % layer1_huffman_loc_number_128_words)

huffaddr = layer1_unified_huff_base_addr_128
print("Starting addr for huff w table: %d" % huffaddr)
for i in range(0, layer1_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    huffaddr += 1

print("Starting addr for huff loc table: %d" % huffaddr)
for i in range(0, layer1_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    huffaddr += 1


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
print("Starting addr for bias: %d" % biaddr)
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1

print("Bias end addr: %d\n" % biaddr)

# easy to read bias file
bias_file = open('weight_files/conv2/bias.txt', 'w')
for i in range(0, layer1_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer1_bias[i]) + '\n')
bias_file.close()


weight_golden = open('weight_files/conv2/weight.txt','w') 
for oc_cnt in range (0, layer1_oc):
    for ic_cnt in range (0, layer1_ic):
        weight_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                weight_golden.write(str(format(layer1_sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
            weight_golden.write('\n')

weight_golden.close()

####################################################
# CONV 3                                           #
####################################################

# these do not need to change per input chunk
layer1_unified_huff_base_addr_128 = int(23734)
layer1_unified_bias_base_addr_128 = int(23760)
layer1_unified_w_base_addr_128    = int(17900)

# params for entire layer1
layer1_ic = int(96)
layer1_oc = int(192)
layer1_true_ic = int(96)
# weights for entire img
conv1_process_kernel_size = int(3)
layer1_w = np.random.randint(-8, high=16, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size), dtype=np.int8)
layer1_bias = np.random.randint(-4, high=4, size=layer1_oc, dtype=np.int8)
np.save("weight_files/conv3/conv3b.npy", layer1_bias)

# sparsify
sparse_loc = (np.random.randint(0, high=2, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size)))
layer1_sparse_w = np.int8((np.multiply(layer1_w, sparse_loc)))
np.save("weight_files/conv3/conv3w.npy", layer1_sparse_w)

##########################################################
layer1_sparse_w = np.load("weight_files/fr_W3_quant.npy")
layer1_bias = np.load("weight_files/fr_b3_quant.npy")

layer1_bias = np.int8(layer1_bias*(2**f_b1))
layer1_bias = np.reshape(layer1_bias,(layer1_oc,))
layer1_sparse_w = np.int8(layer1_sparse_w*(2**f_w1))
layer1_sparse_w = np.reshape(layer1_sparse_w,(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size))
print(np.shape(layer1_sparse_w))
##########################################################

print("layer3 conv3 w density: " + str( (float(np.count_nonzero(layer1_sparse_w))/float(layer1_ic*layer1_oc*conv1_process_kernel_size*conv1_process_kernel_size))*float(100) ) + "%")

# encode the weights
layer1_weight_list = []
layer1_runlength_list = []
layer1_abs_loc_list = [] 

print("layer3_sparse_w shape: "+str( np.array(layer1_sparse_w).shape ))

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

print("layer3_weight_sanity_check_list shape: "+str(np.array(layer1_weight_sanity_check_list).shape))
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
layer1_weight_mapping_file    = open('weight_files/conv3/weight_mapping.txt', 'w')
layer1_weight_table_file      = open('weight_files/conv3/weight_table.txt', 'w')
layer1_weight_raw_file        = open('weight_files/conv3/weight_list_raw.txt', 'w')
layer1_weight_coded_file      = open('weight_files/conv3/weight_list_coded.txt', 'w')
layer1_runlength_mapping_file = open('weight_files/conv3/runlength_mapping.txt', 'w')
layer1_runlength_table_file   = open('weight_files/conv3/runlength_table.txt', 'w')
layer1_runlength_raw_file     = open('weight_files/conv3/runlength_list_raw.txt', 'w')
layer1_runlength_coded_file   = open('weight_files/conv3/runlength_list_coded.txt', 'w')
for item in layer1_weight_list:
  layer1_weight_raw_file.write("%s\n" % item)
layer1_weight_raw_file.close()
for item in layer1_weight_list_coded:
  layer1_weight_coded_file.write("%s\n" % item)
layer1_weight_coded_file.close()
for item in layer1_runlength_list:
  layer1_runlength_raw_file.write("%s\n" % item)
layer1_runlength_raw_file.close()
for item in layer1_runlength_list_coded:
  layer1_runlength_coded_file.write("%s\n" % item)
layer1_runlength_coded_file.close()
for item in layer1_weight_codes:
    layer1_weight_mapping_file.write(str(item) + ' ' + str(layer1_weight_codes[item]) + '\n')
layer1_weight_mapping_file.close()
for subtree in layer1_weight_table:
    for item in subtree:
        if(item ==''):
            layer1_weight_table_file.write('00000000000000' + '\n')
        else:
            layer1_weight_table_file.write(item + '\n')
layer1_weight_table_file.close()
for item in layer1_runlength_codes:
    layer1_runlength_mapping_file.write(str(item) + ' ' + str(layer1_runlength_codes[item]) + '\n')
layer1_runlength_mapping_file.close()
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item ==''):
            layer1_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer1_runlength_table_file.write(item + '\n')
layer1_runlength_table_file.close()

layer1_weight_sanity_check_file = open('weight_files/conv3/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)): 
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer1_weight_sanity_check_file.write(str(format(layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer1_weight_sanity_check_file.write('\n')
layer1_weight_sanity_check_file.close()

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
  
layer1_CWRAM_file = open('weight_files/conv3/CWRAM.txt', 'w')
for item in layer1_CWRAM_word_list:
  layer1_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer1_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()
layer1_CWRAM_file.close()

layer1_CWRAM_full_file = open('weight_files/conv3/CWRAM_full.txt', 'w')
for item in layer1_CWRAM_word_list_full:
  layer1_CWRAM_full_file.write("%s\n" % item)
layer1_CWRAM_full_file.close()

#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer1_unified_w_base_addr_128
print("conv3 weights start at %d" % cwaddr)
for i in range(0, len(layer1_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer1_CWRAM_word_list_full[i]
    cwaddr += 1
print("conv3 weights END at %d" % cwaddr)

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

print("conv3 huff W num words: %d" % layer1_huffman_w_number_128_words)


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

print("conv3 huff LOC num words: %d" % layer1_huffman_loc_number_128_words)

huffaddr = layer1_unified_huff_base_addr_128
print("Starting addr for huff w table: %d" % huffaddr)
for i in range(0, layer1_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    huffaddr += 1

print("Starting addr for huff loc table: %d" % huffaddr)
for i in range(0, layer1_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    huffaddr += 1


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
print("Starting addr for bias: %d" % biaddr)
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1

print("Bias end addr: %d\n" % biaddr)

# easy to read bias file
bias_file = open('weight_files/conv3/bias.txt', 'w')
for i in range(0, layer1_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer1_bias[i]) + '\n')
bias_file.close()


weight_golden = open('weight_files/conv3/weight.txt','w') 
for oc_cnt in range (0, layer1_oc):
    for ic_cnt in range (0, layer1_ic):
        weight_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                weight_golden.write(str(format(layer1_sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
            weight_golden.write('\n')

weight_golden.close()

####################################################
# CONV 4                                           #
####################################################

# these do not need to change per input chunk
layer1_unified_huff_base_addr_128 = int(31531)
layer1_unified_bias_base_addr_128 = int(31559)
layer1_unified_w_base_addr_128    = int(23800)

# params for entire layer1
layer1_ic = int(192)
layer1_oc = int(128)
layer1_true_ic = int(192)
# weights for entire img
conv1_process_kernel_size = int(3)
layer1_w = np.random.randint(-8, high=16, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size), dtype=np.int8)
layer1_bias = np.random.randint(-4, high=4, size=layer1_oc, dtype=np.int8)
np.save("weight_files/conv4/conv4b.npy", layer1_bias)

# sparsify
sparse_loc = (np.random.randint(0, high=2, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size)))
layer1_sparse_w = np.int8((np.multiply(layer1_w, sparse_loc)))
np.save("weight_files/conv4/conv4w.npy", layer1_sparse_w)

##########################################################
layer1_sparse_w = np.load("weight_files/fr_W4_quant.npy")
layer1_bias = np.load("weight_files/fr_b4_quant.npy")

layer1_bias = np.int8(layer1_bias*(2**f_b1))
layer1_bias = np.reshape(layer1_bias,(layer1_oc,))
layer1_sparse_w = np.int8(layer1_sparse_w*(2**f_w1))
layer1_sparse_w = np.reshape(layer1_sparse_w,(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size))
##########################################################

print("layer4 conv4 w density: " + str( (float(np.count_nonzero(layer1_sparse_w))/float(layer1_ic*layer1_oc*conv1_process_kernel_size*conv1_process_kernel_size))*float(100) ) + "%")

# encode the weights
layer1_weight_list = []
layer1_runlength_list = []
layer1_abs_loc_list = [] 

print("layer4_sparse_w shape: "+str( np.array(layer1_sparse_w).shape ))

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

print("layer4_weight_sanity_check_list shape: "+str(np.array(layer1_weight_sanity_check_list).shape))
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
layer1_weight_mapping_file    = open('weight_files/conv4/weight_mapping.txt', 'w')
layer1_weight_table_file      = open('weight_files/conv4/weight_table.txt', 'w')
layer1_weight_raw_file        = open('weight_files/conv4/weight_list_raw.txt', 'w')
layer1_weight_coded_file      = open('weight_files/conv4/weight_list_coded.txt', 'w')
layer1_runlength_mapping_file = open('weight_files/conv4/runlength_mapping.txt', 'w')
layer1_runlength_table_file   = open('weight_files/conv4/runlength_table.txt', 'w')
layer1_runlength_raw_file     = open('weight_files/conv4/runlength_list_raw.txt', 'w')
layer1_runlength_coded_file   = open('weight_files/conv4/runlength_list_coded.txt', 'w')
for item in layer1_weight_list:
  layer1_weight_raw_file.write("%s\n" % item)
layer1_weight_raw_file.close()
for item in layer1_weight_list_coded:
  layer1_weight_coded_file.write("%s\n" % item)
layer1_weight_coded_file.close()
for item in layer1_runlength_list:
  layer1_runlength_raw_file.write("%s\n" % item)
layer1_runlength_raw_file.close()
for item in layer1_runlength_list_coded:
  layer1_runlength_coded_file.write("%s\n" % item)
layer1_runlength_coded_file.close()
for item in layer1_weight_codes:
    layer1_weight_mapping_file.write(str(item) + ' ' + str(layer1_weight_codes[item]) + '\n')
layer1_weight_mapping_file.close()
for subtree in layer1_weight_table:
    for item in subtree:
        if(item ==''):
            layer1_weight_table_file.write('00000000000000' + '\n')
        else:
            layer1_weight_table_file.write(item + '\n')
layer1_weight_table_file.close()
for item in layer1_runlength_codes:
    layer1_runlength_mapping_file.write(str(item) + ' ' + str(layer1_runlength_codes[item]) + '\n')
layer1_runlength_mapping_file.close()
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item ==''):
            layer1_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer1_runlength_table_file.write(item + '\n')
layer1_runlength_table_file.close()

layer1_weight_sanity_check_file = open('weight_files/conv4/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)): 
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer1_weight_sanity_check_file.write(str(format(layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer1_weight_sanity_check_file.write('\n')
layer1_weight_sanity_check_file.close()

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
  
layer1_CWRAM_file = open('weight_files/conv4/CWRAM.txt', 'w')
for item in layer1_CWRAM_word_list:
  layer1_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer1_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()
layer1_CWRAM_file.close()

layer1_CWRAM_full_file = open('weight_files/conv4/CWRAM_full.txt', 'w')
for item in layer1_CWRAM_word_list_full:
  layer1_CWRAM_full_file.write("%s\n" % item)
layer1_CWRAM_full_file.close()

#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer1_unified_w_base_addr_128
print("conv4 weights start at %d" % cwaddr)
for i in range(0, len(layer1_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer1_CWRAM_word_list_full[i]
    cwaddr += 1
print("conv4 weights END at %d" % cwaddr)

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

print("conv4 huff W num words: %d" % layer1_huffman_w_number_128_words)


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

print("conv4 huff LOC num words: %d" % layer1_huffman_loc_number_128_words)

huffaddr = layer1_unified_huff_base_addr_128
print("Starting addr for huff w table: %d" % huffaddr)
for i in range(0, layer1_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    huffaddr += 1

print("Starting addr for huff loc table: %d" % huffaddr)
for i in range(0, layer1_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    huffaddr += 1


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
print("Starting addr for bias: %d" % biaddr)
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1

print("Bias end addr: %d\n" % biaddr)

# eaasy to read bias file
bias_file = open('weight_files/conv4/bias.txt', 'w')
for i in range(0, layer1_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer1_bias[i]) + '\n')
bias_file.close()


weight_golden = open('weight_files/conv4/weight.txt','w') 
for oc_cnt in range (0, layer1_oc):
    for ic_cnt in range (0, layer1_ic):
        weight_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                weight_golden.write(str(format(layer1_sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
            weight_golden.write('\n')

weight_golden.close()

####################################################
# CONV 5                                           #
####################################################

# these do not need to change per input chunk
layer1_unified_huff_base_addr_128 = int(31531)
layer1_unified_bias_base_addr_128 = int(31559)
layer1_unified_w_base_addr_128    = int(23800)

# params for entire layer1
layer1_ic = int(128)
layer1_oc = int(128)
layer1_true_ic = int(128)
# weights for entire img
conv1_process_kernel_size = int(3)
layer1_w = np.random.randint(-8, high=16, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size), dtype=np.int8)
layer1_bias = np.random.randint(-4, high=4, size=layer1_oc, dtype=np.int8)
np.save("weight_files/conv4/conv4b.npy", layer1_bias)

# sparsify
sparse_loc = (np.random.randint(0, high=2, size=(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size)))
layer1_sparse_w = np.int8((np.multiply(layer1_w, sparse_loc)))
np.save("weight_files/conv4/conv4w.npy", layer1_sparse_w)

##########################################################
layer1_sparse_w = np.load("weight_files/fr_W5_quant.npy")
layer1_bias = np.load("weight_files/fr_b5_quant.npy")

layer1_bias = np.int8(layer1_bias*(2**f_b1))
layer1_bias = np.reshape(layer1_bias,(layer1_oc,))
layer1_sparse_w = np.int8(layer1_sparse_w*(2**f_w1))
layer1_sparse_w = np.reshape(layer1_sparse_w,(layer1_oc, layer1_ic, conv1_process_kernel_size, conv1_process_kernel_size))
##########################################################

print("layer4 conv4 w density: " + str( (float(np.count_nonzero(layer1_sparse_w))/float(layer1_ic*layer1_oc*conv1_process_kernel_size*conv1_process_kernel_size))*float(100) ) + "%")

# encode the weights
layer1_weight_list = []
layer1_runlength_list = []
layer1_abs_loc_list = [] 

print("layer4_sparse_w shape: "+str( np.array(layer1_sparse_w).shape ))

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

print("layer4_weight_sanity_check_list shape: "+str(np.array(layer1_weight_sanity_check_list).shape))
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
layer1_weight_mapping_file    = open('weight_files/conv4/weight_mapping.txt', 'w')
layer1_weight_table_file      = open('weight_files/conv4/weight_table.txt', 'w')
layer1_weight_raw_file        = open('weight_files/conv4/weight_list_raw.txt', 'w')
layer1_weight_coded_file      = open('weight_files/conv4/weight_list_coded.txt', 'w')
layer1_runlength_mapping_file = open('weight_files/conv4/runlength_mapping.txt', 'w')
layer1_runlength_table_file   = open('weight_files/conv4/runlength_table.txt', 'w')
layer1_runlength_raw_file     = open('weight_files/conv4/runlength_list_raw.txt', 'w')
layer1_runlength_coded_file   = open('weight_files/conv4/runlength_list_coded.txt', 'w')
for item in layer1_weight_list:
  layer1_weight_raw_file.write("%s\n" % item)
layer1_weight_raw_file.close()
for item in layer1_weight_list_coded:
  layer1_weight_coded_file.write("%s\n" % item)
layer1_weight_coded_file.close()
for item in layer1_runlength_list:
  layer1_runlength_raw_file.write("%s\n" % item)
layer1_runlength_raw_file.close()
for item in layer1_runlength_list_coded:
  layer1_runlength_coded_file.write("%s\n" % item)
layer1_runlength_coded_file.close()
for item in layer1_weight_codes:
    layer1_weight_mapping_file.write(str(item) + ' ' + str(layer1_weight_codes[item]) + '\n')
layer1_weight_mapping_file.close()
for subtree in layer1_weight_table:
    for item in subtree:
        if(item ==''):
            layer1_weight_table_file.write('00000000000000' + '\n')
        else:
            layer1_weight_table_file.write(item + '\n')
layer1_weight_table_file.close()
for item in layer1_runlength_codes:
    layer1_runlength_mapping_file.write(str(item) + ' ' + str(layer1_runlength_codes[item]) + '\n')
layer1_runlength_mapping_file.close()
for subtree in layer1_runlength_table:
    for item in subtree:
        if(item ==''):
            layer1_runlength_table_file.write('00000000000000' + '\n')
        else:
            layer1_runlength_table_file.write(item + '\n')
layer1_runlength_table_file.close()

layer1_weight_sanity_check_file = open('weight_files/conv4/check_weights.txt', 'w')
for oc_cnt_base in range (0, int(layer1_oc/pe_oc)): 
    for ic_cnt_base in range (0, int(layer1_ic/pe_ic)): 
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                for oc_cnt in range (0, pe_oc): 
                    for ic_cnt in range (0, pe_ic):
                        layer1_weight_sanity_check_file.write(str(format(layer1_weight_sanity_check_list[oc_cnt_base][ic_cnt_base][row][col][oc_cnt*pe_ic+ic_cnt], '4d')))
                layer1_weight_sanity_check_file.write('\n')
layer1_weight_sanity_check_file.close()

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
  
layer1_CWRAM_file = open('weight_files/conv4/CWRAM.txt', 'w')
for item in layer1_CWRAM_word_list:
  layer1_CWRAM_file.write("%s\n" % item)
  if(weight_wordsize == 128):
      layer1_CWRAM_word_list_full.append(str(item[0:128]))
  else:
      print("ERROR: bad weight_wordsize given. Plz only use 128.")
      exit()
layer1_CWRAM_file.close()

layer1_CWRAM_full_file = open('weight_files/conv4/CWRAM_full.txt', 'w')
for item in layer1_CWRAM_word_list_full:
  layer1_CWRAM_full_file.write("%s\n" % item)
layer1_CWRAM_full_file.close()

#~~~~~~~
# COMPRESSED WEIGHTS
#~~~~~~~
cwaddr = layer1_unified_w_base_addr_128
print("conv4 weights start at %d" % cwaddr)
for i in range(0, len(layer1_CWRAM_word_list_full)):
    cwram_superset = ((cwaddr >> 11) & 0x3)
    cwram_set      = ((cwaddr >> 13) & 0x7)
    cwram_bank     = ((cwaddr >> 9)  & 0x3)
    cwram_word     =  (cwaddr & 0x1FF)
    if(unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % cwaddr)
    unified_memlist[cwram_superset][cwram_set][cwram_bank][cwram_word] = layer1_CWRAM_word_list_full[i]
    cwaddr += 1
print("conv4 weights END at %d" % cwaddr)

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

print("conv4 huff W num words: %d" % layer1_huffman_w_number_128_words)


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

print("conv4 huff LOC num words: %d" % layer1_huffman_loc_number_128_words)

huffaddr = layer1_unified_huff_base_addr_128
print("Starting addr for huff w table: %d" % huffaddr)
for i in range(0, layer1_huffman_w_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_w_list[i]
    huffaddr += 1

print("Starting addr for huff loc table: %d" % huffaddr)
for i in range(0, layer1_huffman_loc_number_128_words):
    huff_superset = ((huffaddr >> 11) & 0x3)
    huff_set      = ((huffaddr >> 13) & 0x7)
    huff_bank     = ((huffaddr >> 9) & 0x3)
    huff_word     =  (huffaddr & 0x1FF)
    if(unified_memlist[huff_superset][huff_set][huff_bank][huff_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % huffaddr)
    unified_memlist[huff_superset][huff_set][huff_bank][huff_word] = huff_loc_list[i]
    huffaddr += 1


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
print("Starting addr for bias: %d" % biaddr)
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    if(unified_memlist[bias_superset][bias_set][bias_bank][bias_word] != str('0'*unified_wordsize)):
        print("COLLISION FOUND AT ADDR %d!" % biaddr)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1

print("Bias end addr: %d\n" % biaddr)

# eaasy to read bias file
bias_file = open('weight_files/conv4/bias.txt', 'w')
for i in range(0, layer1_oc):
    bias_file.write("OC[%3d]: " % i)
    bias_file.write(str(layer1_bias[i]) + '\n')
bias_file.close()


weight_golden = open('weight_files/conv4/weight.txt','w') 
for oc_cnt in range (0, layer1_oc):
    for ic_cnt in range (0, layer1_ic):
        weight_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
        for row in range (0, conv1_process_kernel_size):
            for col in range (0, conv1_process_kernel_size):
                weight_golden.write(str(format(layer1_sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
            weight_golden.write('\n')

weight_golden.close()


####################################################
# Sparse FC 1                                      #
####################################################

ic = 8*8*8
oc = 256
kernel_size = 1 #fc
ia_size = 1
oa_size = 1
write_ia_num = 0
write_w_num = 0
write_oa_num = 1

#sparse random ws 
w = np.random.randint(-32, high=32, size=(oc, ic, oa_size, oa_size), dtype=np.int8)
sparse_loc = np.random.randint(-20, high=2, size=(oc, ic, oa_size, oa_size),dtype=np.int8).clip(min=0)
sparse_w = np.multiply(w, sparse_loc).astype(np.int8)
print("sparse_fc1 density: " + str(100.0*float(np.count_nonzero(sparse_w))/float(ic*oc*oa_size*oa_size)) + '%')
np.save("weight_files/sparse_fc1/fc1w.npy", sparse_w)

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
                # print ('looking at ic: ' + str(total_ic_cnt*8 + ic_cnt))
                for bank_id in range(0, 64):
                    bank_addr_last[bank_id] = -1
                skip = 0
                while(skip == 0 and last_word == 0):
                    #check if we shall skip this ic
                    skip = 1
                    for bank_id in range (0, 64):
                        for bank_addr in range (0, int(oc/64)):
                            if( bank_addr > bank_addr_last[bank_id] and sparse_w[bank_addr * 64 + bank_id][total_ic_cnt*8+ic_cnt][row][col] != 0 ): 
                                # print ('ic: ' + str(total_ic_cnt*8 + ic_cnt) + '; oc: ' + str(bank_addr * 64 + bank_id) + ' valid, NOT SKIPPING')
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
                                    # print ('ic: ' + str(total_ic_cnt*8 + ic_cnt) + '; oc: ' + str(bank_addr * 64 + bank_id) + ' resolved, bank_addr: ' + str(bank_addr))
                                    tempstr = str(bindigits(bank_addr, 5)) + str(bindigits(sparse_w[bank_addr * 64 + bank_id][total_ic_cnt*8+ic_cnt][row][col], 8))
                                    # print(tempstr)
                                    w_word_total = tempstr + str(w_word_total)
                                    # print(w_word_total)
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
                                        # print(str(bank_addr * 64 + bank_id) + ' unsolved')
                                        last_word = 0

                        #write sram
                        #print(len(w_word_stored))

                        temppstr = str(bindigits(row, 8)) + str(bindigits(col, 8)) + str(bindigits(total_ic_cnt*8+ic_cnt, 12))
                        # print("bigword is done:\n%s\n\n" % temppstr)
                        w_word_write_total = temppstr + str(w_word_stored)
                        w_word_write = '{message:>1024{fill}}'.format(message=w_word_write_total, fill='').replace(' ', '0')
                        w_word_stored = ''
                        #print(len(w_word_write))
                        #print(w_word_write)
                        # print ('writing ic: ' + str(total_ic_cnt*8 + ic_cnt))
                        RRAM_word_list.append(w_word_write)
                        #for j in range(0, 4):
                            #w_mem[write_w_num][j].write(w_word_write[512 + (3-j) * 128: 512 + (4-j) * 128] + '\n')
                            #w_mem[write_w_num+1][j].write(w_word_write[(3-j) * 128: (4-j) * 128] + '\n')
                            #w_mem_cnt[j] = w_mem_cnt[j] + 1
                    if(last_word == 1):
                        # print('write_last_word')
                        w_word_write_total = str(bindigits(oa_size, 8)) + str(bindigits(oa_size, 8)) + str(bindigits(ic, 12)) + str(w_word_total)
                        w_word_write = '{message:>1024{fill}}'.format(message=w_word_write_total, fill='').replace(' ', '0')
                        w_word_stored = ''
                        #print(len(w_word_write))
                        #print(w_word_write)
                        # print ('writing ic: ' + str(total_ic_cnt*8 + ic_cnt))
                        RRAM_word_list.append(w_word_write)


# RRAM_file = open('RRAM.txt', 'w+')
# RRAM_word_list_full = []

# sharedmem_file = open('SHARED.txt', 'w+')
# sharedmem_word_list_full = []
# for item in RRAM_word_list:
#     RRAM_file.write(hexify(item) + '\n')
#     sharedmem_file.write(hexify(item[0:512]) + '\n')
#     sharedmem_file.write(hexify(item[512:1024]) +'\n')

fcwaddr = 7910
print("Starting address of sparse fc1: %d" % fcwaddr)
for i in range(0, len(RRAM_word_list)): # 2048
    fc_superset = ((fcwaddr >> 9) & 0x3)
    fc_set      = ((fcwaddr >> 11) & 0x7)
    fc_word     =  (fcwaddr & 0x1FF)
    # print("fc_superset: %d fc_set: %d fc_word: %d" % (fc_superset,fc_set,fc_word))
    # print(hexify(RRAM_word_list[i])[128:256])
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
    # print("fc_superset: %d fc_set: %d fc_word: %d" % (fc_superset,fc_set,fc_word))
    # print(hexify(RRAM_word_list[i])[0:128])
    unified_memlist[fc_superset][fc_set][3][fc_word] = RRAM_word_list[i][0:128]
    unified_memlist[fc_superset][fc_set][2][fc_word] = RRAM_word_list[i][128:256]
    unified_memlist[fc_superset][fc_set][1][fc_word] = RRAM_word_list[i][256:384]
    unified_memlist[fc_superset][fc_set][0][fc_word] = RRAM_word_list[i][384:512]
    #print(hexify(unified_memlist[fc_superset][fc_set][0][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][1][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][2][fc_word]))
    #print(hexify(unified_memlist[fc_superset][fc_set][3][fc_word]))
    fcwaddr += 1
print("Ending address of sparse fc1: %d" % fcwaddr)



w_golden = open('weight_files/sparse_fc1/weight.txt','w+') 

for ic_cnt in range (0, ic):
    for oc_cnt in range (0, oc):
        for row in range (0, oa_size):
            for col in range (0, oa_size):
                if(sparse_w[oc_cnt][ic_cnt][row][col] != 0):
                    w_golden.write('w channel: [' + str(oc_cnt) + ', ' + str(ic_cnt) + ']\n')
                    w_golden.write(str(format(sparse_w[oc_cnt][ic_cnt][row][col], '4d')) + '\t')
                    w_golden.write('\n')

w_golden.close()

####################################################
# Dense FC 2                                       #
####################################################

fc1_w = np.random.randint(low=-4, high=16, size=(8,8,8))
fc1_w[:,5:,:] = 0
fc1_b = np.random.randint(low=-4, high=10, size=(8,))

np.save("weight_files/dense_fc2/fc2w.npy", fc1_w)
np.save("weight_files/dense_fc2/fc2b.npy", fc1_b)

fc1_base_w_addr_512 = int(10075)
fc1_base_b_addr_128 = int(40428)

wwordlist = []
for i in range(0,4):
    wwordlist.append([])

wword_total = ''
wword_cnt = 0


for filt in range(0,32):
    for row in range(0,8):
        for col in range(0,8):
            wword_total = str(bindigits(fc1_w[row][col][filt],8)) + str(wword_total)
            wword_cnt += 1
            for bank in range(0,4):
                if(wword_cnt == 16*(bank+1)):
                    wwordlist[bank].append(wword_total)
                    wword_total = ''
                    if(bank == 3):
                        wword_cnt = 0


# FC1
fcwaddr = fc1_base_w_addr_512
print("Starting dense_fc2 addr %d %d" % (fcwaddr, fcwaddr*4))
for i in range(0, len(wwordlist[0])): # 2048
    for j in range(0, 4): # 4 banks
        fc_superset = ((fcwaddr >> 9) & 0x3)
        fc_set      = ((fcwaddr >> 11) & 0x7)
        fc_word     =  (fcwaddr & 0x1FF)
        unified_memlist[fc_superset][fc_set][j][fc_word] = wwordlist[j][i]
    fcwaddr += 1
print("Ending dense_fc2 addr %d %d" % (fcwaddr, fcwaddr*4))

# now we have bias_memlist, time to write
bias_memlist=[]
for oc_cnt_base in range(0, int((64/8)/2)): # there are 16 biases/word, not 8
    BRAM_word = ''
    for oc_cnt in range(0, pe_oc*2): # 8
        BRAM_word = str(bindigits(fc1_b[oc_cnt_base*(pe_oc*2)+oc_cnt], 8)) + BRAM_word
    bias_memlist.append(BRAM_word)

# now actual write biases for FC1 & FC2
biaddr = fc1_base_b_addr_128
print("Starting dense_fc2 bias addr %d" % biaddr)
for i in range(0, len(bias_memlist)):
    bias_superset = ((biaddr >> 11) & 0x3)
    bias_set      = ((biaddr >> 13) & 0x7)
    bias_bank     = ((biaddr >> 9) & 0x3)
    bias_word     =  (biaddr & 0x1FF)
    unified_memlist[bias_superset][bias_set][bias_bank][bias_word] = bias_memlist[i]
    biaddr += 1
print("Ending dense_fc2 bias addr %d" % biaddr)

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
                if(unified_memlist[i][j][k][n] != str('0' * 128)):
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
                fd.write("%x\n" % np.sum(memlist_word_valid[i][j][k]))

with open('unified_sram/last_valid_word_in_each_bank.txt', "w") as fd:
        for j in range(0,unified_sets):
            for i in range(0,unified_supers):
                for k in range(0,unified_banks):
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

                #if(args.longword):
                unified_files[i][j][k].write(hexify(unified_memlist[i][j][k][n]) + '\n')
                #else:
                #    hexxx = hexify(unified_memlist[i][j][k][n])
                #    for q in range(0,16):
                #        unified_files[i][j][k].write("%s" % hexxx[(q*2)+1])
                #        unified_files[i][j][k].write("%s\n" % hexxx[q*2])


for i in range(0,unified_supers): #superset
    unified_files.append([])
    for j in range(0,unified_sets): #set
        unified_files[i].append([])
        for k in range(0,unified_banks): #bank
            unified_files[i][j][k].close()


print("\nDONE")
