import math
import libra
import sys

small_frame =int(eval(sys.argv[1]))
if small_frame == 1:
	mcb_x_start = int(eval(sys.argv[2]))
	mcb_y_start = int(eval(sys.argv[3]))
	mcb_x_num   = int(eval(sys.argv[4]))
	mcb_y_num   = int(eval(sys.argv[5]))
else :
	mcb_x_start = 0
	mcb_y_start = 0
	mcb_x_num   = 40 
	mcb_y_num   = 30
mcb_index_x_start =(mcb_x_start/16) 
mcb_index_y_start =(mcb_y_start/16) 
mcb_index_x_end   =mcb_index_x_start + mcb_x_num -1
mcb_index_y_end   =mcb_index_y_start + mcb_y_num -1
mcb_index_list = []
for mcb_index_y in range(mcb_index_y_start,mcb_index_y_end+1):
	for mcb_index_x in range(mcb_index_x_start,mcb_index_x_end+1):
		mcb_index_list.append( mcb_index_y * 40 + mcb_index_x)

chip = libra.libra(0)
chip.img_if_direct_mem_access_on()

# write
f = open("./y_pnt_mem.txt",'w')
data_list = []
data_list.extend(chip.mbus.send_memory_read(2,(0xA0413810/4),1200*2,1,0)[1][1:])
for item in data_list:
	print >> f, item[0]
f.close()
chip.img_if_direct_mem_access_off()

# make it compact
cnt = 0
mcb_cnt = 0
next_addr = 0
f = open("./y_pnt_mem.txt",'r')
fw = open("./y_pnt_mem_part.txt",'w')
lines = f.readlines()
for line in lines:
	if cnt % 2 == 0:
		buf=line.strip()
	else :
		buf=line.strip()+buf
		size3 = buf[(10+0*10):(10+1*10)]
		size2 = buf[(10+1*10):(10+2*10)]
		size1 = buf[(10+2*10):(10+3*10)]
		size0 = buf[(10+3*10):(10+4*10)]
		addr  = buf[(10+4*10):]
		if mcb_cnt in mcb_index_list :
			print >> fw, (size3+size2+size1+size0+addr)
		mcb_cnt = mcb_cnt + 1
	cnt = cnt + 1
f.close()
fw.close()

# check
f = open("./y_pnt_mem_part.txt",'r')
	
cnt = 0
mcb_cnt = 0
next_addr = 0
prev_size = 0
lines = f.readlines()
for line in lines:
	buf=line.strip()
	size3 = buf[(0*10):(1*10)]
	size2 = buf[(1*10):(2*10)]
	size1 = buf[(2*10):(3*10)]
	size0 = buf[(3*10):(4*10)]
	addr  = buf[(4*10):]
	#print "size3:",size3
	#print "  size2:",size2
	#print "  size1:",size1
	#print "  size0:",size0
	#print "  addr:",addr
	if int(addr,2) != next_addr:
	   print "ERR, line:", cnt+1, "calculatd_addr from prev:", next_addr, "prev_data_size :",prev_size, "addr", int(addr,2)
	total_size = int(size3,2) + int(size2,2) + int(size1,2) + int(size0,2)
	addr_consum = int(math.ceil(total_size/64.0))
	if total_size%64 == 0 :
	   addr_consum = addr_consum + 1
	   #if cnt == 119 or cnt == 1148:
	   #   print "DBG, line:", cnt
	next_addr = int(addr_consum + int(addr,2))
	prev_size = total_size
	cnt = cnt + 1
f.close()
