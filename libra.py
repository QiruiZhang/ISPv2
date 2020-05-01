from colorama import Fore, Back, Style
from colorama import init
import pymbus_ft232h
import itertools

import time
import os
import subprocess

import numpy as np

global printperline
printperline = 5

class libra():
	def __init__(self,newinstance=1):
		init()
		self.mbus = pymbus_ft232h.PYMBUS_FT232H(newinstance)# {{{
		self.sigmap = {} #ex {'signame' : [registernum, startbit, length]}
		self._load_sigmap()
		self.orgdict = {}
		self._load_orgdict()
		return# }}}

	##### initiate class API #################################################
	def _load_sigmap(self,filename=r".\02_registermap\registermap.ereg.txt"):
		# {{{
		print "- libra2 : loading sigmap for ereg from %s"%(filename)
		ifile = open(filename,'r')
		#ex {'signame' : [registernum, startbit, length]}
		for line in ifile:
			tline = line.strip().split('#')[0].strip()
			if tline == '': pass
			else:
				regnum = int(tline.split()[0])
				siglist = tline.split()[1].split(',')
				for item in siglist:
					signame = item.split(':')[-1]
					busnote = (':'.join(item.split(':')[:-1])).strip('[]')
					startbit = int(busnote.split(':')[1]) if len(busnote.split(':'))==2 else int(busnote)
					length = int(busnote.split(':')[0])-int(busnote.split(':')[1])+1 if len(busnote.split(':'))==2 else 1
					self.sigmap[signame] = [regnum,startbit,length]
		return# }}}

	def _load_orgdict(self,filename=r".\02_registermap\registermap.dictionary.txt"):
                #{{{
		print "- libra2 : loading orgdict from %s"%(filename)
		ifile = open(filename,'r')
		#ex groupname : signame0,signame1,signame2
		for line in ifile:
			tline = line.strip().split('#')[0].strip()
			if tline == '': pass
			else:
				groupname = tline.split(':')[0].strip()
				signames = tline.split(':')[1].strip()
				signame_list = [item.strip() for item in signames.split(',')]
				self.orgdict[groupname] = signame_list[:]
		return# }}}

	def print_sigmap(self):
		#ex {'signame' : [registernum, startbit, length]}# {{{
		i = 0
		print "\nsignal map : [regnum, startbit, length]"
		print "\t",
		for key,item in self.sigmap.iteritems():
			print "%28s"%key,"%15s"%str(item),
			if ((i+1)%5==0 and i != len(self.sigmap.keys())-1):
				print ""
				print "\t",
			elif (i == len(self.sigmap.keys())-1):
				print "\n"
			i += 1
		return# }}}

	def print_orgdict(self):
		#ex {'keyword' : [signames]}# {{{
		keys = sorted(self.orgdict.keys())
		print "\n"
		for key in keys:
			item = self.orgdict[key]
			print "%18s||\t"%key,
			for j in range(0, len(item)):
				print "%-25s\t"%item[j],
				if ((j+1)%5==0 and j != len(item)-1):
					print ""
					print "%20s\t"%(''),
				elif (j == len(item)-1):
					print "\n%20s"%(''),'-'*(125+8*4),'\n'
		return# }}}

	##### register read/write API ############################################
	def read(self,keyword,memberid=2,verbose=0,vv=0):
		# datalist = (...,[regaddr(int), data(str)], ...){{{
		if keyword in self.orgdict.keys(): #block read
			print '\t- libra2 : reading register block %s'%(keyword)
			def _read_reg_iter(keyword,verbose,vv):
				blocknames = self.orgdict[keyword]
				signames = []
				regnums = []
				datalist = {}
				print '\t- libra2 : printing register block %s'%(keyword) 
				for item in blocknames: 
					if item in self.orgdict.keys(): #another block
						(temp_signames,temp_datalist) = _read_reg_iter(item,verbose=verbose,vv=vv)
						datalist.update(temp_datalist)
						signames.append(temp_signames)
					else: #single signal
						signames.append(item)
				#get signal values
				for signame in signames:
					if type(signame) == type([]): pass
					else :
						(regnum,startbit,length) = self.sigmap[signame]
						print '\t\tlibra2 : reading %s from reg=%d, startbit=%d, length=%d'%(signame,regnum,startbit,length)
						if regnum not in regnums: regnums.append(regnum)
				for item in regnums:
					(addrstr,temp_datalist) = self.mbus.send_register_read(memberid,item,1,1,0,verbose=verbose,vv=vv) #single length read of 32b
					datalist[item] = temp_datalist[0] #single length read of 32b
				return signames,datalist
			def _print_reg_iter(signames,datalist,blockname,tab):	
				outputdata = []
				print ('\t'*tab)+'\t'+'='*100
				print ('\t'*tab)+'\tlibra2 : register block ** %s ** output'%(blockname)
				#print signals
				for signame in signames:
					if type(signame) == type([]):
						_print_reg_iter(signame,datalist,self.orgdict[blockname][signames.index(signame)],tab+1)
					else:
						#{'signame' : [registernum, startbit, length]}
						(regnum,startbit,length) = self.sigmap[signame]
						datastr = list(datalist[regnum][1])[::-1] #24b length
						return_data = int(''.join(datastr[startbit:startbit+length][::-1]),2)
						outputdata.append([signame,str(return_data)+'/'+str(pow(2,length)-1)])
				outputdata = [list(x) for x in zip(*outputdata)]
				output_nameline = ''
				output_dataline = ''
				outputdatalen = len(outputdata)
				for i in range(0, 0 if outputdatalen==0 else len(outputdata[0])):
					output_nameline = output_nameline + "\t\t%24s"%(outputdata[0][i])
					output_dataline = output_dataline + "\t\t%24s"%(outputdata[1][i])
					if (i%printperline == printperline-1) or i == len(outputdata[0])-1: 
						print ('\t'*tab)+"%4d"%(i/printperline*printperline),output_nameline
						print ('\t'*tab)+"%4s"%(''),output_dataline
						output_nameline = ''
						output_dataline = ''
				print ('\t'*tab)+'\t'+'='*100
				return
			(top_signames,top_datalist) = _read_reg_iter(keyword,verbose=verbose,vv=vv)
			print ''
			_print_reg_iter(top_signames,top_datalist,keyword,0)
			print ''
			return top_signames,top_datalist
		elif keyword in self.sigmap.keys() : #individual read
			#{'signame' : [registernum, startbit, length]}
			(regnum,startbit,length) = self.sigmap[keyword]
			print '\t- libra2 : reading signal %s @reg=%d,bit=%d,length=%d'%(keyword,regnum,startbit,length)
			(addrstr,datalist) = self.mbus.send_register_read(memberid,regnum,1,1,0,verbose=verbose,vv=vv)
			#datalist = [...,[regaddr(int),datastr],...]
			datastr = list(datalist[0][1])[::-1] #24b length
			return_data = int(''.join(datastr[startbit:startbit+length][::-1]),2)
			print '\t'+'='*100
			print '\t%24s = %d/%d (%s)'%(keyword,return_data,pow(2,length)-1,bin(return_data)[2:].zfill(length))
			print '\t'+'='*100
			return keyword,return_data
		else:
			raise LibraError("\t\tlibra2 : LibraError : cannot find %s from namespace\n\n"%(keyword))
		return # }}}
	
	def write(self,keyword,valuelist,memberid=2,verbose=0,vv=0):
		if keyword in self.orgdict.keys() : #block write# {{{
			print '\t- libra2 : writing register block %s'%(keyword), valuelist
			(signames,datalist) = self.read(keyword,verbose=verbose,vv=vv)
			if len(signames) != len(valuelist): 
				raise LibraError("\t\tlibra2 : LibraError : length mismatch, #ofSignals=%d & #ofValues=%d\n\n"%(len(signames),len(valuelist)))
			def _write_reg_iter(valuelist,signames,datalist,verbose,vv):
				#get signal values
				for i in range(0, len(signames)):
					if type(signames[i]) == type([]): #another block
						_write_reg_iter(valuelist[i],signames[i],datalist)
					else: #single signal
						signame = signames[i]
						value = valuelist[i]
						(regnum,startbit,length) = self.sigmap[signame]
						tempdata = list(datalist[regnum][1])[::-1]
						tempdata[startbit:startbit+length] = list(bin(value)[2:].zfill(length))[::-1]
						datalist[regnum][1] = ''.join(tempdata[::-1])
				return
			def _send_reg_iter(datalist,verbose,vv):
				#write regs
				for regnum,data in datalist.iteritems():
					self.mbus.send_register_write(memberid,[[regnum,data[1]]],verbose=verbose,vv=vv)
				return
			_write_reg_iter(valuelist,signames,datalist,verbose=verbose,vv=vv)
			_send_reg_iter(datalist,verbose=verbose,vv=vv)
		elif keyword in self.sigmap.keys() : #individual write
			#{'signame' : [registernum, startbit, length]}
			(regnum,startbit,length) = self.sigmap[keyword]
			print '\t- libra2 : writing signal %s @reg=%d,bit=%d,length=%d'%(keyword,regnum,startbit,length), valuelist
			(addrstr,datalist) = self.mbus.send_register_read(memberid,regnum,1,1,0,verbose=verbose,vv=vv)
			#datalist = [...,[regaddr(int),datastr],...]
			datastr = list(datalist[0][1])[::-1] #24b length
			if type(valuelist[0]) == type(''):
				valuestr = list(valuelist[0].zfill(length)[::-1])
			else:
				valuestr = list(bin(valuelist[0])[2:].zfill(length)[::-1])
			for i in range(startbit,startbit+length):
				datastr[i] = valuestr[i-startbit]
			outputdatastr = ''.join(datastr[::-1])
			self.mbus.send_register_write(memberid,[[regnum,outputdatastr]],verbose=verbose,vv=vv)
		else:
			raise LibraError("\t\tlibra2 : LibraError : cannot find %s from namespace\n\n"%(keyword))
		print "\t- libra2 : executing call-back"
		self.read(keyword,verbose=verbose,vv=vv)
		print "\t- libra2 : DONE writing registers"
		return# }}}

	##### Instruction memory API #############################################
	def read_imem(self,numread=512,memberid=2):
		ofile = open('memread.log','w')# {{{
		self.write('ctrl_sleep',[0],memberid)
		self.write('ctrl_isolate',[0],memberid)
		self.write('enable_lc_mem',[1],memberid)
		(addrstr,datalist) = self.mbus.send_memory_read(memberid,0,numread,1,0,verbose=1,vv=0) #should be 1024 but second-half of imem cannot be read due to h/w bug
		self.write('enable_lc_mem',[0],memberid)
		self.write('ctrl_isolate',[1],memberid)
		self.write('ctrl_sleep',[1],memberid)
		for i in range(0, len(datalist)):
			if i%2==1: print >>ofile,datalist[i][0] #datalist[0] = DMA start address
		ofile.close()
		return# }}}
	
	def compile_program(self,filename):
		print "\t###############################"# {{{
		print "\t#### Compiling VIM program ####"
		print "\t###############################"
		prep_scriptpath = 'VIM_preprocessor.py'
		assem_scriptpath = 'VIM_assembler.py'
		format_scriptpath = 'VIM_formatter.py'
		regfile_path = os.path.join('02_registermap','registermap.rel.txt')
		prepfilename = '.'.join(filename.split('.')[:-1])+'.preprocessed'
		machinefilename = '.'.join(filename.split('.')[:-1])+'.output.machine'
		formatmachinefilename = machinefilename+'.formatted'
		if os.path.exists(prepfilename): os.remove(prepfilename)
		p0 = subprocess.Popen(['python',prep_scriptpath,filename],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
		(tmp_stdout,tmp_stderr)=p0.communicate()
		print "\t- VIM_preprocessor : ",filename
		if tmp_stderr != '':	
			print "\t\tERROR!"
			print tmp_stderr
			raise LibraError("")
		else: 
			print "\t\tNO ERROR from",prep_scriptpath
		if os.path.exists(machinefilename): os.remove(machinefilename)
		p1 = subprocess.Popen(['python',assem_scriptpath,prepfilename,regfile_path],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
		(tmp_stdout,tmp_stderr)=p1.communicate()
		print "\t- VIM_assembler : ",prepfilename
		if tmp_stderr != '':	
			print "\t\tERROR!"
			print tmp_stderr
			raise LibraError("")
		else: 
			print "\t\tNO ERROR from",assem_scriptpath
		if os.path.exists(formatmachinefilename): os.remove(formatmachinefilename)
		p2 = subprocess.Popen(['python',format_scriptpath,machinefilename],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
		(tmp_stdout,tmp_stderr)=p2.communicate()
		print "\t- VIM_formatter : ",machinefilename
		if tmp_stderr != '':	
			print "\t\tERROR!"
			print tmp_stderr
			raise LibraError("")
		else: 
			print "\t\tNO ERROR from",format_scriptpath
			print '\t\tlast line',tmp_stdout.split('\n')[-2:]
		print "\t###############################"
		print "\t#### Compiling DONE !! ########"
		print "\t###############################"
		return# }}}
		
	def write_imem(self,filename,memberid=2):
		prepfilename = '.'.join(filename.split('.')[:-1])+'.preprocessed'# {{{
		machinefilename = '.'.join(filename.split('.')[:-1])+'.output.machine'
		formatmachinefilename = machinefilename+'.formatted'
		ifile = open(formatmachinefilename,'r')
		ofile = open('memwrite.log','w')
		datalist = []
		for line in ifile:
			templine = line.split()[0].strip()
			if templine == '': pass
			if len(templine) != 32: 
				raise LibraError("\t\tLibraError : formatted machine code length not 32")
			else: datalist.append(templine)
		self.write('ctrl_sleep',[0],memberid)
		self.write('ctrl_isolate',[0],memberid)
		self.write('enable_lc_mem',[1],memberid)
		self.mbus.send_memory_bulkwrite(memberid,0,datalist,verbose=1,vv=0)
		self.write('enable_lc_mem',[0],memberid)
		self.write('ctrl_isolate',[1],memberid)
		self.write('ctrl_sleep',[1],memberid)
		for item in datalist:
			print >>ofile,item
		return# }}}

	##### memory APIs : preset test sequences ################################
	def memory_init(self,tune=0,memberid=2,verbose=0,vv=0):
		print(Fore.YELLOW + '- libra2 : memory initialization')#{{{
		print(Style.RESET_ALL)
		if tune is 1:
			print '- libra2 : tune SRAM banks'
			#self.write('sram_instr_tuning',[31,63,31,2],verbose=verbose,vv=vv) slow SRAM
			self.write('sram_instr_tuning',       [31,63,10,2],verbose=verbose,vv=vv) #isp37 demo
			self.write('sram64x512_imgif_tuning', [31,63,10,2],verbose=verbose,vv=vv) #isp37 demo
			self.write('sram128x512_imgif_tuning',[31,63,10,2],verbose=verbose,vv=vv) #isp37 demo
			self.write('sram128x512_ne_tuning',   [31,63,10,2],verbose=verbose,vv=vv) #isp37 demo
			self.write('sram32x32_ne_tuning',     [31,63,10,2],verbose=verbose,vv=vv) #isp37 demo
			self.write('sram_h264_tuning',        [31,63,10,2],verbose=verbose,vv=vv) #isp37 demo
			#self.write('sram_instr_tuning',       [31,47,10,2],verbose=verbose,vv=vv) #isp37 max
			#self.write('sram64x512_imgif_tuning', [31,47,10,2],verbose=verbose,vv=vv) #isp37 max
			#self.write('sram128x512_imgif_tuning',[31,47,10,2],verbose=verbose,vv=vv) #isp37 max
			#self.write('sram128x512_ne_tuning',   [31,47,10,2],verbose=verbose,vv=vv) #isp37 max
			#self.write('sram32x32_ne_tuning',     [31,47,10,2],verbose=verbose,vv=vv) #isp37 max
			#self.write('sram_h264_tuning',        [31,47,10,2],verbose=verbose,vv=vv) #isp37 max
			#self.write('sram_instr_tuning',       [31,40,10,2],verbose=verbose,vv=vv) #isp35 max
			#self.write('sram64x512_imgif_tuning', [31,40,10,2],verbose=verbose,vv=vv) #isp35 max
			#self.write('sram128x512_imgif_tuning',[31,40,10,2],verbose=verbose,vv=vv) #isp35 max
			#self.write('sram128x512_ne_tuning',   [31,40,10,2],verbose=verbose,vv=vv) #isp35 max
			#self.write('sram32x32_ne_tuning',     [31,40,10,2],verbose=verbose,vv=vv) #isp35 max
			#self.write('sram_h264_tuning',        [31,40,10,2],verbose=verbose,vv=vv) #isp35 max
		print '- libra2 : SRAM reset release' 
		self.write('sram_resetn',[1,1,1,1],verbose=verbose,vv=vv)
		print '- libra2 : SRAM isolate release'
		self.write('sram_isolate',[0,0,0,0],verbose=verbose,vv=vv)

		#Main mem sw configuration
		print '- libra2 : MAIN SRAM SW value setting'
		addr_list = []
		for i in range(16):
			addr_list.append((0+i*1024*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(1024*4)/4,1,1,0,verbose=verbose,vv=vv) # this should not be the first address you access

		print '- libra2 : IMGIF SRAM setting'
		self.img_if_reset_enable_on()
		self.img_if_direct_mem_access_on()
		print '\t- libra2 : MINMAX mem 64x512(1)'
		self.mbus.send_memory_bulkwrite(memberid,(0xA0410290/4),[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0410290+10*4)/4,1,1,0,verbose=verbose,vv=vv) # this should not be the first address you access
		print '\t- libra2 : CD mem 64x512(4) 128x512(4)'
		addr_list = []
		for i in range(4):
			addr_list.append((0xA0400000 + 0xF0 + i*4*8*512)/4)
			addr_list.append((0xA0400000 + 0xF0 + i*4*8*512 + 2*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0400000 + 0xF0 + 4*8*512)/4,1,1,0,verbose=verbose,vv=vv) # this should not be the first address you access
		print '\t- libra2 : REF mem 64x512(3)'
		addr_list = []
		for i in range(3):
			addr_list.append((0xA0400000 + 0x4D810 + i*2*512*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0400000 + 0x4D810 + 2*512*4)/4,1,1,0) # this should not be the first address you access
		print '\t- libra2 : COMP mem 64x512(55)' #55 SRAM banks
		addr_list = []
		for i in range(36):
			addr_list.append((0xA0413810+i*2*512*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0413810+2*512*4)/4,1,1,0)
		addr_list = []
		for i in range(36,55):
			addr_list.append((0xA0413810+i*2*512*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0413810+37*1024*4)/4,1,1,0)
		self.img_if_reset_enable_off()
		self.img_if_direct_mem_access_off()

		#Neural engine configuration
		print '- libra2 : NE SRAM setting'
		self.ne_reset_enable_on()
		self.ne_autogate_pe_disable()
		print '\t- libra2 : NE shared mem 128x512(80)'
		addr_list = []
		for i in range(80):
			addr_list.append((0xA0104100+i*2048*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0104100+2048*4)/4,1,1,0)
		print '\t- libra2 : NE weight mem 256x256(4)'
		addr_list = []
		addr_list.append((0xA01CC100+0*4)/4)
		addr_list.append((0xA01CC100+8*4)/4)
		addr_list.append((0xA01D0100+0*4)/4)
		addr_list.append((0xA01D0100+8*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA01CC100+16*4)/4,1,1,0)
		print '\t- libra2 : NE instr mem 128x256(2)'
		addr_list = []
		addr_list.append((0xA0100100+0*4)/4)
		addr_list.append((0xA0100100+4*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0100100+8*4)/4,1,1,0)
		print '\t- libra2 : NE local mem 256x256(4)'
		addr_list = []
		addr_list.append((0xA01C4100+0*4)/4)
		addr_list.append((0xA01C4100+8*4)/4)
		addr_list.append((0xA01C8100+0*4)/4)
		addr_list.append((0xA01C8100+8*4)/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA01C4100+12*4)/4,1,1,0)
		#print '\t- libra2 : NE accum mem 32x32(64)'
		#addr_list = []
		#for i in range(64):
		#	addr_list.append((0xA01D4100+i*32*4)/4)
		#for addr in addr_list:
		#	self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		print '\t- libra2 : NE bias mem 128x512(1)'
		addr_list = []
		addr_list.append(0xA01D6100/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA01D6100 + 8*4)/4,1,1,0)
		self.ne_autogate_pe_enable()

		#H264 configuration
		print '- libra2 : H264 SRAM setting'
		self.h264_reset_enable_on()
		self.h264_direct_mem_access_on()
		addr_list = []
		addr_list.append(0xA0200038/4)
		for addr in addr_list:
			self.mbus.send_memory_bulkwrite(memberid,addr,[0x00ff00ff],verbose=verbose,vv=vv)
		self.mbus.send_memory_read(memberid,(0xA0200038 + 8*4)/4,1,1,0)
		self.h264_direct_mem_access_off()
		self.h264_reset_enable_off()

		print '- libra2 : SRAM SWRW release'
		self.write('sram_swrw',[0,0,0,0],verbose=verbose,vv=vv)
		return# }}}

	def write_prog_mem(self,filename='./01_maincodes/design_tb_0.hex',memberid=2,compare=1,startaddr=0,verbose=1,vv=0):
		print(Fore.YELLOW + '\t- libra2 : memory write') #{{{
		print(Style.RESET_ALL)
		#ifile = open('./01_maincodes/'+filename,'r')
		ifile = open(filename,'r')
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
		self.mbus.send_memory_bulkwrite(memberid,startaddr,datalist,verbose=verbose,vv=vv)
		if compare is 1 :
			ofile_memread= open('memread.log','w')
			(fuid,returned_datalist)=self.mbus.send_memory_read(2,startaddr,len(datalist),1,0,verbose=1,vv=0)
			returned_datalist = list(itertools.chain(*returned_datalist))
			returned_datalist = [int(s,2) for s in returned_datalist]
			if datalist == returned_datalist[1:] :
				print "Yei ^^"
			else:
				print(Fore.RED + 'Nei :(')
				print(Style.RESET_ALL)
				for item in returned_datalist[1:]:
					print >>ofile_memread,bin(item)[2:].zfill(32)
				time.sleep(5)
			ofile_memread.close()
	
		for item in datalist:
			print >>ofile_memwrite,bin(item)[2:].zfill(32)
		ofile_memwrite.close()
		return# }}}

	def set_osc(self,osc_sd=0x11,osc_div=0x2,memberid=2,verbose=0,vv=0):
		print(Fore.YELLOW + '- libra2 : Oscillator setting')#{{{
		print(Style.RESET_ALL)
		#self.write('clock_tuning',[0,osc_sd,osc_div],verbose=verbose,vv=vv)
		self.write('osc_sd',[osc_sd],verbose=verbose,vv=vv)
		self.write('osc_div',[osc_div],verbose=verbose,vv=vv)
		return# }}}
	def run_cpu(self,memberid=2,verbose=1,vv=0):
		print(Fore.YELLOW + '- libra2 : cpu run set')#{{{
		print(Style.RESET_ALL)
		self.write('run_cpu',[1],verbose=verbose,vv=vv)
		return# }}}
	def stop_cpu(self,memberid=2,verbose=1,vv=0):
		print(Fore.YELLOW + '- libra2 : cpu run reset')#{{{
		print(Style.RESET_ALL)
		self.write('run_cpu',[0],verbose=verbose,vv=vv)
		return# }}}
	def img_if_reset_enable_on(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : img if reset enable ON')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0400000/4),data_list=[0x11],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0400000), .MEM_VALUE(32'h11), .NUM_BULK(1))://img_if_ctrl(softreset,enable)
		return# }}}
	def img_if_reset_enable_off(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : img if reset enable OFF')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0400000/4),data_list=[0x01],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0400000), .MEM_VALUE(32'h01), .NUM_BULK(1))://img_if_ctrl(softreset,enable)
		return# }}}
	def img_if_direct_mem_access_on(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : img if direct mem access ON')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0400004/4),data_list=[0x00],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0400004), .MEM_VALUE(32'h00), .NUM_BULK(1))://img_mode=0,img_type=0
		return# }}}
	def img_if_direct_mem_access_off(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : img if direct mem access OFF')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0400004/4),data_list=[0x10],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0400004), .MEM_VALUE(32'h10), .NUM_BULK(1)):
		return# }}}
	def ne_reset_enable_on(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : ne reset ON')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0100000/4),data_list=[0x11],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0100000), .MEM_VALUE(32'h11), .NUM_BULK(1))://NE_enable(softreset,enable)
		return# }}}
	def ne_autogate_pe_disable(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : ne autogate pe DISABLE')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA010006C/4),data_list=[0x00],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA010006C), .MEM_VALUE(32'h00), .NUM_BULK(1))://NE_autogate_pe
		return# }}}
	def ne_autogate_pe_enable(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : ne autogate pe ENABLE')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA010006C/4),data_list=[0x11],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA010006C), .MEM_VALUE(32'h11), .NUM_BULK(1))://NE_autogate_pe
		return# }}}
	def h264_reset_enable_on(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : h264 reset enable ON')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0200004/4),data_list=[0x11],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0200004), .MEM_VALUE( 32'h11), .NUM_BULK(1))://h264_enable(softreset,enable)
		return# }}}
	def h264_reset_enable_off(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : h264 reset enable OFF')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0200004/4),data_list=[0x01],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0200004), .MEM_VALUE( 32'h01), .NUM_BULK(1))://h264_enable(softreset,enable)
		return# }}}
	def h264_direct_mem_access_on(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : h264 direct memory acess ON')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0200020/4),data_list=[0x101],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0200020), .MEM_VALUE(32'h101), .NUM_BULK(1))://h264_debug(debug_sram_sel,debug_out_sel)
		return# }}}
	def h264_direct_mem_access_off(self,memberid=2,verbose=0,vv=0):
		print('- libra2 : h264 direct memory acess OFF')#{{{
		self.mbus.send_memory_bulkwrite(memberid=memberid,startaddr=(0xA0200020/4),data_list=[0x000],verbose=verbose,vv=vv)
		#mbus_memory_bulk_write(.SHORT_PREFIX(`CMP_ADDR), .MEM_ADDR(32'hA0200020), .MEM_VALUE(32'h000), .NUM_BULK(1))://h264_debug(debug_sram_sel,debug_out_sel)
		return# }}}

	def read_mem_result(self,address=0x3c00,count=10,memberid=2,verbose=1,vv=0):
		print('- libra2 : read memory result')#{{{
		self.mbus.send_memory_read(memberid,(address/4),count,1,0,verbose,vv)
		return# }}}

	def ne_instr_mem_write(self,basepath='./01_maincodes/ne/dbgnets',memberid=2,compare=1,verbose=1,vv=0):
		print(Fore.YELLOW + '- libra2 : NE instr mem write') #{{{
		print(Style.RESET_ALL)
		self.write_prog_mem(filename=basepath+'/ne_instructions.byte',memberid=memberid,compare=compare,startaddr=(0xA0100100/4),verbose=verbose,vv=vv)
		return# }}}
	
	def ne_shared_mem_write(self,basepath='./01_maincodes/ne/dbgnets',memberid=2,compare=1,startaddr=0,verbose=1,vv=0):
		print(Fore.YELLOW + '- libra2 : NE shared mem write') #{{{
		print(Style.RESET_ALL)
		File         = open(basepath+r'/unified_sram/empty_or_valid.txt','r');
		super_cnt = 0
		set_cnt   = 0
		bank_cnt  = 0
		i         = 0
		for valid in File:
			if int(valid) == 1:
                                filename = '/in_'+str(super_cnt)+'_'+str(set_cnt)+'_'+str(bank_cnt)+'.bytes'
				startaddr= 0xA0104100 +(128*512)/8 * i
				print(Fore.GREEN + '\t- libra2 : NE shared mem load '+ filename + "  startaddr :" + str(hex(startaddr)))
				self.write_prog_mem(filename=basepath+'/unified_sram'+filename,memberid=memberid,compare=0,startaddr=(startaddr/4),verbose=verbose,vv=vv)
			if bank_cnt == 3:
				if super_cnt ==3:
					bank_cnt = 0
					super_cnt = 0
					set_cnt   = set_cnt + 1
				else:
					bank_cnt  = 0
					super_cnt = super_cnt + 1
			else:
				bank_cnt = bank_cnt + 1
			i         = i + 1 
		return# }}}
		
	##### memory APIs : boot test sequences ################################
	def boot(self,filename='./01_maincodes/design_tb_0.hex',memberid=2,osc_sd=0x1C,osc_div=2,ne_use=0,ne_basepath='./01_maincodes/ne/dbgnets',compare=0,verbose=1,vv=0):
		self.set_osc(memberid=memberid,osc_sd=osc_sd,osc_div=osc_div,verbose=verbose,vv=vv)
		self.memory_init(tune=1,memberid=memberid,verbose=verbose,vv=vv)
		if ne_use == 1 :
			self.ne_instr_mem_write(basepath=ne_basepath,memberid=2,compare=0,verbose=1,vv=0)
			self.ne_shared_mem_write(basepath=ne_basepath,memberid=2,compare=0,verbose=verbose,vv=0)
		time.sleep(1)
		print(Fore.YELLOW + '- libra2 : main mem write')
		print(Style.RESET_ALL)
		self.write_prog_mem(filename=filename,memberid=memberid,compare=compare,startaddr=0,verbose=verbose,vv=vv)
		time.sleep(1)
		return

	##### memory APIs : debug SRAM ################################
	def read_mem_indi(self,read_list):
		ofiler = open("readmem_indi.log","w")
		returned_datalist = []
		for start_addr,read_len in read_list:
			(fuid,temp_returned_datalist)=self.mbus.send_memory_read(2,start_addr,read_len,1,0,verbose=1,vv=0)
			returned_datalist = returned_datalist + temp_returned_datalist[1:]
			#returned_datalist = temp_returned_datalist[1:]+returned_datalist 
		returned_datalist = list(itertools.chain(*returned_datalist))
		returned_datalist = [int(s,2) for s in returned_datalist]
		for item in returned_datalist:
			print >>ofiler,bin(item)[2:].zfill(32)
		return

	def sleep_seq(self,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print "\t\tlibra2 : sleep zzZ"
		self.write('run_cpu',[0],verbose=verbose,vv=vv)
		self.write('sram_isolate',[1,1,1,1],verbose=verbose,vv=vv)
		self.mbus.broadcast_allsleep()

	def cdmap_write(self,filename='./04_goldenbrick/cdmap_readable.txt',memberid=2,startaddr=(0xA040004C/4),verbose=1,vv=0):
		print(Fore.YELLOW + '\t- libra2 : cdmap overwrite') #{{{
		print(Style.RESET_ALL)
		ifile = open(filename,'r')
		datalist = []
		tempchunk=''
		cnt = 0
		for line in ifile:
			templine = line.split()[0].strip()
			datalist.append(int(templine,2))
		self.mbus.send_memory_bulkwrite(memberid,startaddr,datalist,verbose=verbose,vv=vv)
		return# }}}

class Error(Exception):
	pass

class LibraError(Error):
	def __init__(self,expression):
		print expression


def main():
	return

if __name__ == "__main__":
	main()

