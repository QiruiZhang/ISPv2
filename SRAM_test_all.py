from colorama import Fore, Back, Style
from colorama import init
import time
import libra
import itertools

# Import the email modules we'll needb
#from email.mime.text import MIMEText
# Import smtplib for the actual sending function
import smtplib
usr = 'jingcheng.wang.program@gmail.com'
password = 'pythonAutoSend'
allowEmailAlert = False

chipID      = 'ISP03'
VDD_core    = '0p6'
VDD_mem     = '0p377'

chip = libra.libra()
#chip.boot()
chip.boot(filename='design_tb_20.hex',verbose=1,vv=0)

def memory_compare(chip, filename='design_tb_0.hex',memberid=2,startaddr=0,verbose=1,vv=0):
	print(Fore.YELLOW + '- libra2 : main PROGRAM write')
	print(Style.RESET_ALL)
	ifile = open('./01_maincodes/'+filename,'r')
	ofile_memwrite= open('memwrite.log','w')
	datalist = []
	tempchunk=''
	cnt = 0
	for line in ifile:
		templine = line.split()[0].strip()
		tempchunk = templine + tempchunk
		if cnt == 3:
			cnt = 0
			datalist.append(int(tempchunk,16))
			tempchunk=''
		else:
			cnt = cnt + 1
        ifile.close()
	chip.mbus.send_memory_bulkwrite(memberid,startaddr,datalist,verbose=verbose,vv=vv)
	
        ofile_memread= open('memread.log','w')
	(fuid,returned_datalist)=chip.mbus.send_memory_read(2,startaddr,len(datalist),1,0,verbose=1,vv=0)
	returned_datalist = list(itertools.chain(*returned_datalist))
	returned_datalist = [int(s,2) for s in returned_datalist]

        errorlist=[]
	if datalist == returned_datalist[1:] :
		print "Yei ^^"
                correct=True
	else:
		print(Fore.RED + 'Nei :(')
		print(Style.RESET_ALL)
                correct=False

                for i in range(len(datalist)):
                    if datalist[i] != returned_datalist[i+1]:
                        errorlist.append((hex(i), bin(datalist[i])[2:].zfill(32), bin(returned_datalist[i+1])[2:].zfill(32),bin(datalist[i]^returned_datalist[i+1])[2:].zfill(32))) 
        
        ofile_memread.close()
	ofile_memwrite.close()

        if not correct:
            #errorlist=[('a','b','c','d')]
            msg = 'Subject: Main Memory has {} error word\n'.format(len(errorlist))
            msg += "addr\torigin\tactual\txor\n"
            for item in errorlist:
                msg += "{}\t{}\t{}\t{}\n".format(item[0],item[1],item[2],item[3])
            
            if allowEmailAlert:
                send_email(usr, password, msg)
            
            filename = "./05_memorytest/{}_MainMem_{}_{}.log".format(chipID, VDD_core, VDD_mem)
            ofile = open(filename,'w')
            ofile.write(msg)
            ofile.close()
            exit()
        return 

def send_email(usr,password,msg):
    #server = smtplib.SMTP('smtp.gmail.com',587)
    #server.starttls()
    server = smtplib.SMTP_SSL('smtp.gmail.com',465)
    server.login(usr,password)
    server.sendmail(usr, usr, msg)
    server.quit()
    return


##debug CLK
chip.write('debug',[3,7]) #1:h264 2:tx 3:rx 4:fls 5:ne 6:vga 7:clk_lc


#Main Memory Test
memory_compare(chip, filename='Main_SRAM_testPattern.hex',startaddr=0)
memory_compare(chip, filename='Main_SRAM_testPattern_C.hex',startaddr=0)


#Load M0 to test all other MEM
chip.write_prog_mem(filename='SRAM_test_all.hex',startaddr=0)
start = time.time()
chip.run_cpu()
time.sleep(30)
(key,run_cpu) = chip.read('run_cpu')
time_out = 0
while(run_cpu!=0):
    time.sleep(30)
    (key,run_cpu) = chip.read('run_cpu')
    time_out = time_out + 1
    if(time_out == 60):
        break;
    (fuid,returned_datalist)=chip.mbus.send_memory_read(2,0x3C00/4,30,1,0)

total_time = time.time()-start
print 'total time %s' %(total_time)

(fuid,returned_datalist)=chip.mbus.send_memory_read(2,0x3C00/4,30,1,0)
returned_datalist = list(itertools.chain(*returned_datalist))
returned_datalist = [int(s,2) for s in returned_datalist]
word_error_cnt = returned_datalist[1]
single_word_cnt = returned_datalist[2]
multi_word_cnt = returned_datalist[3]
bit_error_cnt = returned_datalist[4]
single_bit_cnt = returned_datalist[5]
multi_bit_cnt = returned_datalist[6]

test_log = 'Subject: MEM Test finished\n'
test_log += 'total time %s second\n' %total_time
test_log += 'total_word_tested:\t %s \n' %returned_datalist[7]
test_log += 'word_error_cnt   :\t %s \n' %word_error_cnt
test_log += 'single_word_cnt  :\t %s \n' %single_word_cnt
test_log += 'multi_word_cnt   :\t %s \n' %multi_word_cnt
test_log += 'bit_error_cnt    :\t %s \n' %bit_error_cnt
test_log += 'single_bit_cnt   :\t %s \n' %single_bit_cnt
test_log += 'multi_bit_cnt    :\t %s \n' %multi_bit_cnt
test_log += '1. MINMAX MEM    \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[8] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[20] & 0x0FFFFFFF)
test_log += '2. CD MEM        \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[9] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[21] & 0x0FFFFFFF)
test_log += '3. REF MEM       \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[10] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[22] & 0x0FFFFFFF)
test_log += '4. COMP MEM      \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[11] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[23] & 0x0FFFFFFF)
test_log += '5. NE shared MEM \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[12] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[24] & 0x0FFFFFFF)
test_log += '6. NE weight MEM \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[13] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[25] & 0x0FFFFFFF)
test_log += '7. NE Instr MEM  \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[14] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[26] & 0x0FFFFFFF)
test_log += '8. NE local MEM  \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[15] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[27] & 0x0FFFFFFF)
test_log += '9. NE accum MEM  \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[16] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[28] & 0x0FFFFFFF)
test_log += '10. NE Bias MEM  \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[17] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[29] & 0x0FFFFFFF)
test_log += '11. NE Bias MEM  \t   \n' 
test_log += '\tsingle word  :\t %s \n' %(returned_datalist[18] & 0x0FFFFFFF)
test_log += '\tmulti  word  :\t %s \n' %(returned_datalist[30] & 0x0FFFFFFF)

if allowEmailAlert:
	send_email(usr, password, test_log)

filename = "./05_memorytest/{}_all_{}_{}.log".format(chipID, VDD_core, VDD_mem)
ofile_memread= open(filename,'w')
ofile_memread.write(test_log)
ofile_memread.close()

#chip.read_prog_mem(filename='ISP07_all_0p6_0p353.log',startaddr=0x3C00/4,length=30)

