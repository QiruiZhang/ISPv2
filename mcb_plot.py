import math
import numpy as np
import matplotlib.pyplot as plt
import libra
import sys
import datetime
import time

date = datetime.datetime.now().strftime("%m%d")
hour = datetime.datetime.now().strftime("%H%M")
chip = libra.libra(0)
mcb_x_start = int(eval(sys.argv[1]))
mcb_y_start = int(eval(sys.argv[2]))
mcb_x_num   = int(eval(sys.argv[3]))
mcb_y_num   = int(eval(sys.argv[4]))
mcb_index_x_start =(mcb_x_start/16) 
mcb_index_y_start =(mcb_y_start/16) 
mcb_index_x_end   =mcb_index_x_start + mcb_x_num -1
mcb_index_y_end   =mcb_index_y_start + mcb_y_num -1
print_mcb_list = [[0,0]]
check =0

img = np.zeros(((mcb_index_y_end-mcb_index_y_start+1)*16,(mcb_index_x_end-mcb_index_x_start+1)*16))

for mcb_index_y in range(mcb_index_y_start,mcb_index_y_end+1):
	for mcb_index_x in range(mcb_index_x_start,mcb_index_x_end+1):
		mcb_index = mcb_index_y * 40 + mcb_index_x
		data_list = []
		print("mcb_index_x:  ", mcb_index_x, "\tmcb_index_y:  ",mcb_index_y)
		#data_list.extend(chip.mbus.send_memory_read(2,(0xA0411290+mcb_index*4)/4,(16*16)/4,1,0)[1][1:])
		data_list.extend(chip.mbus.send_memory_read(2,(0xA0411290+mcb_index*4)/4,(16*16)/4,1,0)[1][1:])
		cnt = 0
		#for i in range(16*16/4):
		#	if i % 4 == 0:
		#		data_list[i:i+4] = data_list[i:i+4][::-1]
		#for i in range(64):
		#	data_list.extend(chip.mbus.send_memory_read(2,(0xA0411290+mcb_index*4)/4,1,1,0)[1][1:][::-1])
		cnt = 0
		data_list_parsed = []
		for item in data_list:
			if cnt % 4 == 0:
				data_list_parsed.append([])
			data_list_parsed[-1].extend(reversed([int(item[0][i:i+8],2) for i in range(0,32,8)]))
			cnt = cnt + 1
		if mcb_index_x == 0 and mcb_index_y == 0:
			base_path = r'.\03_captures'
			filename = r"\mcb_y_" + str(mcb_index_x) + "+" + str(mcb_index_y)+"_%s_%s"%(date,hour) + ".txt"
			f = open(base_path+filename,'w')
			for item in data_list_parsed:
				f.write(item)
			f.close()
		img[(mcb_index_y-mcb_index_y_start)*16:(mcb_index_y-mcb_index_y_start+1)*16,(mcb_index_x-mcb_index_x_start)*16:(mcb_index_x-mcb_index_x_start+1)*16] = np.array(data_list_parsed)

##filename = "mcb_y_" + str(mcb_index) + ".txt"
##f = open(filename,'w')
##for data in data_list:
##	print >> f, data[0]
##f.close()
#
#f = open(filename,'r')
#cnt = 0
#next_addr = 0
#stride =4
#mcb_list = []
#mcb_buf  = np.zeros((16,16))
#for line in f:
#	buf = line.strip()
#	#buf=buf.split()
#	buf=[buf[i:i+8] for i in range(0,32,8)]
#	#[pixel3, pixel2, pixel1, pixel0] = buf
#	#print buf
#	if cnt % 4 == 0:
#		mcb_list.append([])
#	for pixel in buf:
#		mcb_list[-1].append(int(pixel,2))
#
#	cnt = cnt + 1

#f.close()    
fig1 = plt.figure()
ax = fig1.add_subplot(1, 1, 1)
ax.imshow(img, cmap='gray', norm=None, interpolation=None, vmin=0, vmax=255)

plt.show()
