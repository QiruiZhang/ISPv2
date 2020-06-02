import datetime
import time
import libra
import libraview
import colorama
from colorama import init
from colorama import Fore, Back, Style
import glob
import os 
import subprocess as sp

colorama.init()
print(Fore.CYAN)
print(Style.BRIGHT)

chipname='isp37'
mainvol ='0P600V'
arrvol  ='0P405V'

rerun = input("\n\tRerun?(y/n):   ")
print("\n")
if rerun == "y":
	chip = libra.libra(0)
	chip.stop_cpu()
	chip.run_cpu()
	exit()
else:
	chip = libra.libra()

mem_test = input("\n\tMemory test?(y/n):   ")
if mem_test == "y":
	mem_test_sel = input("\n\tWhat memory test? (0)Main memory (1) Imager interface (2) Neural Engine? (3) IMG IF & NE intense :")
	if mem_test_sel == 0 :
		print('\n**** Main memory Test ****')
		time.sleep(2)
		chip.boot(filename='SRAM_test_IMGall.hex',compare=1,verbose=1,vv=0)
	elif mem_test_sel == 1 :
		print('\n**** Imager Interface memory Test ****')
		time.sleep(2)
		chip.boot(filename='SRAM_test_IMGall_H264.hex',compare=1,verbose=1,vv=0)
	elif mem_test_sel == 2 :
		print('\n**** Neural Engine memory Test ****')
		time.sleep(2)
		chip.boot(filename='SRAM_test_NE.hex',compare=1,verbose=1,vv=0)
	elif mem_test_sel == 3 :
		print('\n**** Imager Interface memory Test ****')
		time.sleep(2)
		chip.boot(filename='SRAM_test_IMG_intense.hex',compare=1,verbose=1,vv=0)
	else :
		raise LibraError("\t\tlibra2 : LibraError : wrong option")
	#0x3C00 : number of word that has error
	#0x3C04 : number of word that has single bit error (<=2)
	#0x3C08 : number of word that has multibits error (>2)
	#0x3C0C : number of bits which is wrong
	#0x3C10 : number of bits which is a single bit error (<=2)
	#0x3C10 : number of bits which is a multi bit error (>2)
	#0x4000 ~ 0x7FFC : every error address (4096 lines)
	#0x8000 ~ 0xBFFC : every word that has error #(4096 lines)
	#0xC000 ~ 0xFFFC : XOR result between true data and data that has error #(4096 lines)
else :
	while 1:
		print('\n\n\
			\nPROGRAM0:sfrmapintegrity            \
			\nPROGRAM1:refframeintegrity          \
			\nPROGRAM2:curframeintegrity          \
			\nPROGRAM3:debuggingpathbayer         \
			\nPROGRAM4:MotionDetection            \
			\nPROGRAM5:MBUS                       \
			\nPROGRAM6:4x4MCBSMALLFRAME           \
			\nPROGRAM7:FULLSCENARIO               \
			\nPROGRAM8:CHANGEDMCBONLYH264         \
			\nPROGRAM9:DEBUGGINGMBUSSTEP          \
			\nPROGRAM10:H264DEBUGGINGPATH         \
			\nPROGRAM11:NEDEBUGGINGPATH           \
			\nPROGRAM12:YFLSDEBUGGINGPATH         \
			\nPROGRAM13:GFLSDEBUGGINGPATH         \
			\nPROGRAM14:FACEDETECTTRIAL           \
			\nPROGRAM15:SRAMACCESS                \
			\nPROGRAM16:4x4MCBREFFRAMEINTEGRITY   \
			\nPROGRAM17:4x4MCBCURFRAMEINTEGRITY   \
			\nPROGRAM18:4x4MCBCURFRAMEINTEGRITY   \
			\nPROGRAM21:MDframestream-inandFLSTest\
			\nPROGRAM23:4x4MCBREFFRAMEINTEGRITYDBG\
			\nPROGRAM24:4x4MCBREFFRAMEBAYERDBG    \
			\nPROGRAM25:4x4MCBREFFRAMEYFLSOUT     \
                       ')
		test_num = input("\n\tWhich program?:    ")
		#sel      = input("\n\tSelection(yuv/h264/cdmap/full/ne/bayer)?:    ")
		#filename = r'./01_maincodes/'+'/software/design_tb_{}_{}'+'/design_tb_{}_{}.hex',test_num,sel,test_num,sel)
		filename = r'./01_maincodes/'+'/software/design_tb_{}'.format(test_num)+'/design_tb_{}.hex'.format(test_num)
		if   str(test_num) == "help":
			pass
		else:
			ne_use = 0
			ne_basepath='./01_maincodes/'+'NE'
			print('\n\n\t=========================================================')
			if int(test_num) == 0 :
				print("\t==========PROGRAM0:sfr map   integrity         =========");
				break
			elif int(test_num) == 1 :
				print("\t==========PROGRAM1:ref frame integrity         =========");
				break
			elif int(test_num) == 2 :
				print("\t==========PROGRAM2:cur frame integrity         =========");
				break
			elif int(test_num) == 3 :
				print("\t==========PROGRAM3:debugging path bayer        =========");
				break
			elif int(test_num) == 4 :
				print("\t==========PROGRAM4:Motion Detection            =========");
				ne_use = 1
				ne_basepath= ne_basepath + 'real_nets/person_detect'
				break
			elif int(test_num) == 5 :
				print("\t==========PROGRAM5:MBUS                      (NA) =========");
				break
			elif int(test_num) == 6 :
				print("\t==========PROGRAM6:4x4MCB SMALL FRAME FULL   (NA)  =========");
				break
			elif int(test_num) == 7 :
				print("\t==========PROGRAM7:FULL SCENARIO             (NA)  =========");
				break
			elif int(test_num) == 8 :
				print("\t==========PROGRAM8:CHANGED MCB ONLY H264     (NA)  ========");
				break
			elif int(test_num) == 9 :
				print("\t==========PROGRAM9:DEBUGGING MBUS STEP             ========");
				break
			elif int(test_num) == 10:
				print("\t==========PROGRAM10:H264 DEBUGGING PATH      (NA)  ========");
				break
			elif int(test_num) == 11:
				print("\t==========PROGRAM11:NE DEBUGGING PATH        (NA)  ========");
				break
			elif int(test_num) == 12:
				print("\t==========PROGRAM12:Y FLS DEBUGGING PATH        ========");
				break
			elif int(test_num) == 13:
				print("\t==========PROGRAM13:G FLS DEBUGGING PATH        ========");
				break
			elif int(test_num) == 14:
				print("\t==========PROGRAM14: FACE DETECT TRIAL 4x4 MCB  ========");
				break
			elif int(test_num) == 15:
				print("\t==========PROGRAM15:SRAM ACCESS            (NA) ========");
				break
			elif int(test_num) == 16:
				print("\t==========PROGRAM16:4x4 MCB REF FRAME INTEGRITY ========");
				break
			elif int(test_num) == 17:
				print("\t==========PROGRAM17:4x4 MCB CUR FRAME INTEGRITY ========");
				break
			elif int(test_num) == 18:
				print("\t==========PROGRAM18:4x4 MCB CUR FRAME INTEGRITY ========");
				break
			elif int(test_num) == 19:
				break
			elif int(test_num) == 20:
				break
			elif int(test_num) == 21:
				print('\t==========PROGRAM21:MD frame stream-in and FLS Test ========');
				break
			elif int(test_num) == 22:
				print('\t==========PROGRAM22:JUST DBG scratch pad            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets'
				break
			elif int(test_num) == 23:
				print('\t==========PROGRAM23:4x4 MCB REF FRAME INTEGRITY DBG ========');
				break
			elif int(test_num) == 24:
				print('\t==========PROGRAM24:4x4 MCB REF FRAME BAYER    DBG  ========');
				break
			elif int(test_num) == 25:
				print('\t==========PROGRAM25:4x4 MCB REF FRAME Y FLS OUT     ========');
				break
			elif int(test_num) == 26:
				print('\t==========PROGRAM26:SRAM init & sleep                ========');
				chip.memory_init(tune=1,memberid=2,verbose=1,vv=0)
				chip.sleep_seq()
				raise LibraError("\t\tlibra2 : Finish")
				break
			elif int(test_num) == 27:
				print('\t==========PROGRAM27:hang                             ========');
				break
			elif int(test_num) == 28:
				print('\t==========PROGRAM28:m0 invalid access                ========');
				break
			elif int(test_num) == 29:
				print('\t==========PROGRAM29:ref frame in & hang              ========');
				break
			elif int(test_num) == 30:
				print('\t==========PROGRAM30:ref decompress                   ========');
				break
			elif int(test_num) == 31:
				print('\t==========PROGRAM31:cur strin                        ========');
				break
			elif int(test_num) == 32:
				print('\t==========PROGRAM32:h264                        ========');
				break
			elif int(test_num) == 33:
				print('\t==========PROGRAM33:NE dbg nets CONV                ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_conv'
				break
			elif int(test_num) == 34:
				print('\t==========PROGRAM34:NE dbg nets CONV+Relu            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_convrelu'
				break
			elif int(test_num) == 35:
				print('\t==========PROGRAM35:NE dbg nets mov only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_mov'
				break
			elif int(test_num) == 36:
				print('\t==========PROGRAM36:NE dbg nets DFC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_dfc'
				break
			elif int(test_num) == 37:
				print('\t==========PROGRAM37:NE dbg nets maxpool            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_maxpool'
				break
			elif int(test_num) == 38:
				print('\t==========PROGRAM38:NE dbg nets DFC avgpool            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_avgpool'
				break
			elif int(test_num) == 39:
				print('\t==========PROGRAM39:NE dbg nets s FC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_sfc_ic64_oc64'
				break
			elif int(test_num) == 40:
				print('\t==========PROGRAM39:NE dbg nets s FC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_sfc_ic64_oc128'
				break
			elif int(test_num) == 41:
				print('\t==========PROGRAM39:NE dbg nets s FC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_sfc_ic64_oc256'
				break
			elif int(test_num) == 42:
				print('\t==========PROGRAM39:NE dbg nets s FC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_sfc_ic64_oc512'
				break
			elif int(test_num) == 43:
				print('\t==========PROGRAM39:NE dbg nets s FC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_sfc_ic64_oc1024'
				break
			elif int(test_num) == 44:
				print('\t==========PROGRAM39:NE dbg nets s FC only            ========');
				ne_use = 1
				ne_basepath= ne_basepath + '/dbgnets_sfc_ic64_oc2048'
				break
			elif int(test_num) == 99:
				print('\t==========PROGRAM99:just freq                        ========');
				# 37ISP
				#chip.set_osc(memberid=2,osc_sd=0x10,osc_div=3,verbose=1,vv=0)#125*2K + 117.6K
				#chip.set_osc(memberid=2,osc_sd=0x1C,osc_div=2,verbose=1,vv=0)#153.8K(0.6V)/120K(0.58V)
				#chip.set_osc(memberid=2,osc_sd=0x19,osc_div=2,verbose=1,vv=0)#133K(0.58V)
				#chip.set_osc(memberid=2,osc_sd=0x17,osc_div=2,verbose=1,vv=0)#143K(0.58V)
				#chip.set_osc(memberid=2,osc_sd=0x13,osc_div=2,verbose=1,vv=0)#166K(0.58V)
				#chip.set_osc(memberid=2,osc_sd=0x10,osc_div=2,verbose=1,vv=0)#200K(0.58V)
				#chip.set_osc(memberid=2,osc_sd=0x10,osc_div=2,verbose=1,vv=0)#250K (0.6V) / 

				# 04ISP
				#chip.set_osc(memberid=2,osc_sd=0x17,osc_div=2,verbose=1,vv=0)#181K(0.6V)
				#chip.set_osc(memberid=2,osc_sd=0x17,osc_div=3,verbose=1,vv=0)#90K(0.6V)
				##chip.write('ext_memclksel',[1],verbose=1,vv=0)
				#chip.write('debug',[6,7])

				# 05ISP
				#chip.set_osc(memberid=2,osc_sd=0x17,osc_div=2,verbose=1,vv=0)#181K(0.6V)
				chip.set_osc(memberid=2,osc_sd=0x17,osc_div=3,verbose=1,vv=0)#90K(0.6V)
				chip.write('ext_memclksel',[1],verbose=1,vv=0)
				#chip.write('debug',[6,7])

				#chip.set_osc(memberid=2,osc_sd=0x17,osc_div=3,verbose=1,vv=0)#181K(0.6V)
				raise LibraError("\t\tlibra2 : Finish")
				break
				break
			else :
				raise LibraError("\t\tlibra2 : LibraError : wrong option")

	print('\t=========================================================')
	time.sleep(3)
	#chip.boot(filename=filename,osc_sd=0x10,osc_div=3,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #122.7 0.6V
	#chip.boot(filename=filename,osc_sd=0x1C,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #153.8 0.6V / 250K 0.65
	#chip.boot(filename=filename,osc_sd=0x18,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #250 0.6V
	#chip.boot(filename=filename,osc_sd=0x17,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #290K 0.65V
	#chip.boot(filename=filename,osc_sd=0x14,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #330K 0.65V
	chip.boot(filename=filename,osc_sd=0x17,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #150K 0.58V
	#chip.boot(filename=filename,osc_sd=0x11,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0) #166K 0.58V
	#chip.boot(filename=filename,osc_sd=0x19,osc_div=2,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0)#133K 0.58V 
	#chip.boot(filename=filename,osc_sd=0x10,osc_div=4,memberid=2,compare=0,ne_use=ne_use,ne_basepath=ne_basepath,verbose=0,vv=0)#133K 0.65V
	print(Fore.RESET)

##debug
chip.write('debug',[6,7]) #1:h264 2:tx 3:rx 4:fls 5:ne 6:vga 7:clk_lc
##timeout enable
#chip.mbus.send_memory_bulkwrite(memberid=2,startaddr=(0xA04100F0/4),data_list=[0x1000])

#check data
time.sleep(2)
chip.run_cpu()
print(Fore.YELLOW + '\n- libra2 : CPU is running.....')
print(Style.RESET_ALL)

#GPIO read
chip.mbus.send_register_read(2,0,10,1,0,verbose=1,vv=0)

#if int(test_num)==8:
#	nop = str(raw_input("\n\tcdmap?:   "))
#	chip.cdmap_write()
#	chip.mbus.send_register_read(2,0,1,1,0,verbose=1,vv=0)

#dump
print("\nExecute dump.py\n")
sp.call('python dump.py ' + r'./03_captures/' + chipname)

#chip.mbus.send_memory_read(2,(0xA0440810/4),1,1,0,verbose=1,vv=0)

#extract valid value only
list_of_files = glob.glob('./03_captures/'+ chipname + '/*')
latest_file = max(list_of_files, key=os.path.getctime)
print(latest_file)
sp.call(['fls_bin_handle.exe',latest_file,'480','640','8','2'],shell=True)

