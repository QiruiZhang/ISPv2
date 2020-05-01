import math
import libra
import sys

chip = libra.libra(0)
chip.img_if_direct_mem_access_on()

mcb_addr1 = 0
mcb_addr2 = 386
num_word1 = 216
num_word2 = 3*2

# write
f = open("./read_CDMEM.txt",'w')
data_list = []
data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F0)/4,4096*8,1,0)[1][1:])
for item in data_list:
	print >> f, item[0]
f.close()
#f = open("./read_CDMEM1.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F0)/4,1024,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#f = open("./read_CDMEM2.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F8)/4,2048,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#f = open("./read_CDMEM3.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F0)/4,1024,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#
#f = open("./read_CDMEM4.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F8)/4,2048,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#f = open("./read_CDMEM5.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F0)/4,1024,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#f = open("./read_CDMEM6.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F8)/4,2048,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#f = open("./read_CDMEM7.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F0)/4,1024,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#
#f = open("./read_CDMEM8.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA04000F8)/4,2048,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()
#f = open("./read_data2.txt",'w')
#data_list = []
#data_list.extend(chip.mbus.send_memory_read(2,(0xA0418810+(2*mcb_addr2)*4)/4,num_word2,1,0)[1][1:])
#for item in data_list:
#	print >> f, item[0]
#f.close()

chip.img_if_direct_mem_access_off()

