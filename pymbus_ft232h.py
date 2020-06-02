
import time
import ftd2xx
from ftd2xx import defines as ft

global packet_length
packet_length = 32
global command_width
command_width = 10

class PYMBUS_FT232H():
	def __init__(self, newinstance=1,nummembers=1,ftID=0,verbose=0,vv=0):
		if verbose: print("\t\tpymbus : initializing ft232h")
		self.dev = _MBUS_FT232H_device(newinstance,ftID,verbose,vv)
		self.comgen = _MBUS_FT232H_command_generator()
		self.dev.flush(verbose,vv)
		if newinstance:
			self.setup_mbus(nummembers)
		return

	def setup_mbus(self,nummembers=1):
		self.broadcast_interject()
		time.sleep(1)
		for i in range(0,nummembers):
			self.broadcast_enumerate(i+2)
		return

	def read_didocico_single(self,verbose=1,vv=0):
		if vv: verbose=1
		commands = ''
		commands += self.comgen.command_read_didocico_single(verbose,vv)
		self.dev.send(commands,verbose,vv)
		read_str = bin(ord(self.dev.read(1,verbose,vv)))[2:]
		return (int(read_str[-1]),int(read_str[-2]),int(read_str[-3]),int(read_str[-4]))

	def read_didocico_multiple_bufferonly(self,length,verbose=1,vv=0):
		if vv: verbose=1
		return_list = []
		read_str_list = [bin(ord(x))[2:] for x in self.dev.read(length,verbose,vv)]
		for i in range(length):
			return_list.append((int(read_str_list[i][-1]),int(read_str_list[i][-2]),int(read_str_list[i][-3]),int(read_str_list[i][-4])))
		return return_list[:]

	def write_doco_single(self,do,co,verbose=1,vv=0):
		if vv: verbose=1
		commands = ''
		commands += self.comgen.command_write_doco_single(do,co,verbose,vv)
		self.dev.send(commands,verbose,vv)
		return

	def write_doco_multiple(self,doco_pairs,verbose=1,vv=0):
		if vv: verbose=1
		if len(doco_pairs) == 0:
			return
		else:
			commands = ''
			## doco_pairs = ((do1,co1),(do2,co2)....)
			for pairs in doco_pairs:
				commands += self.comgen.command_write_doco_single(pairs[0],pairs[1],verbose,vv)
			self.dev.send(commands,verbose,vv)
		return

	def write_message_asMaster(self,addrstr,datastr,maxtry=5,verbose=1,vv=0):
		if vv: verbose=1
		if vv: print("\t\t\tpymbus.write_message_asMaster : writing message to member as master")
		if len(addrstr) != 8:
			print("\t\tfunction write_message_asMaster, arg 'addrstr' needs to be length of 8")
			return 0 #fail
		addrlist = []
		datalist = []
		try:
			for item in addrstr:
				addrlist.append(int(item))
			for item in datastr:
				datalist.append(int(item))
		except ValueError :
			raise MbusError('\t\tMbusError : function write_message_asMaster, arg "addrstr" and "datastr" needs to be a sequence of numbers\n\n')
			return 0
		for j in range(maxtry):
			## declare bus
			i_doco_pairs = [(1,1),(0,1)]
			self.dev.flush(verbose,vv)
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			self.dev.flush(verbose,vv)
			(di,do,ci,co) = self.read_didocico_single(verbose,vv)
			timeout_count = 0
			while (di == 1):
				if timeout_count > 1024:
					raise MbusError('\t\tMbusError : function write_message_asMaster, bus declaration timeout\n\n')
				self.dev.flush(verbose,vv)
				(di,do,ci,co) = self.read_didocico_single(verbose,vv)
				timeout_count += 1
			if vv: print("\t\t\t- master bus declared!")
			## arbitration - 3clk
			i_doco_pairs = []
			i_doco_pairs.extend([(0,0),(0,1),(0,0),(0,1),(0,0),(0,1)])
			## writting MBUS address
			if verbose: print("\t\t\t- writing message\t\t%s,\t"%(addrstr)),
			for i in range(0,len(addrlist)):
				i_doco_pairs.append((addrlist[i],0))
				i_doco_pairs.append((addrlist[i],1))
			i_doco_pairs.append((0,0))
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			## writting MBUS data
			i_doco_pairs = []
			bit_count = 0
			tempdata_str = ''
			for i in range(len(datalist)):
				i_doco_pairs.append((datalist[i],0))
				i_doco_pairs.append((datalist[i],1))
				bit_count += 1
				tempdata_str += str(datalist[i])
				if bit_count%8 == 0:
					if verbose: print(tempdata_str)
					tempdata_str = ''
				if bit_count%32 == 0:
					if verbose: print('\n\t\t\t\t\t\t\t\t\t')
				if bit_count%packet_length == 0:
					self.write_doco_multiple(i_doco_pairs,verbose,vv)
					i_doco_pairs = []
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			if verbose: print(tempdata_str,' - eom')
			## interjection
			i_doco_pairs = []
			i_doco_pairs.append((0,1))
			for i in range(6):
				i_doco_pairs.append((1,1))
				i_doco_pairs.append((0,1))
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			## control bits : #- b1 - don't care #- b2 - EndOfMessage = 1 #- b3 - Acknowledge = 1 (nak)
			i_doco_pairs = [(0,0),(0,1),(1,0),(1,1),(1,0)]
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			time.sleep(0.01)
			self.dev.flush(verbose,vv)
			(di,do,ci,co) = self.read_didocico_single(verbose,vv)
			self.write_doco_multiple([(1,1),(1,0),(1,1)],verbose,vv) #- b4 - don't care : back to default [1,1]
			if di == 0 :
				if verbose: print("\t\t\t- SUCCESS! message acknowledged!")
			else:
				if verbose: print("\t\t\t- FAILED! no acknowledgment...!")
			self.dev.flush(verbose,vv)
			success_flag = (di == 0)
			if success_flag == 1 :
				break	
		return success_flag #success

	def read_response_asMaster(self,maxtry=5,verbose=1,vv=0):
		masterid=1
		if vv: verbose=1
		if vv: print("\t\t\tpymbus.read_response_asMaster : reading response from member as master")
		if vv: print("\t\t\t- waiting for member bus declaration ")
		for j in range(maxtry):
			## detect channel declaration
			self.write_doco_single(1,1,verbose,vv)
			self.dev.flush(verbose,vv)
			(di,do,ci,co) = self.read_didocico_single(verbose,vv)
			if di != 0:
				self.write_doco_single(1,1,verbose,vv)
				time.sleep(0.5)
				continue
				#raise MbusError('\t\tMbusError : function read_response_asMaster, no bus declaration from members\n\n')
			if vv: print("\t\t\t- member declared bus!")
			addrlist = []
			datalist = []
			## arbitration - 3clk
			i_doco_pairs = [(1,0),(1,1),(1,0),(0,0),(0,1),(0,0),(0,1),(0,0)]
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			## read addr
			commands = ''
			for i in range(8):
				commands += self.comgen.command_write_doco_single(1,0,verbose,vv)
				commands += self.comgen.command_read_didocico_single(verbose,vv)
				commands += self.comgen.command_write_doco_single(1,1,verbose,vv)
			self.dev.send(commands,verbose,vv)
			read_str_list = self.read_didocico_multiple_bufferonly(8,verbose,vv)
			addrlist = [str(x[0]) for x in read_str_list]
			## read data
			count = 0
			if verbose: print("\t\t\t- reading message\t\t%s,\t"%(''.join(addrlist)))
			tempdata_str = ''
			while (1):
				commands = ''
				for i in range(0,packet_length):
					commands += self.comgen.command_write_doco_single(1,0,verbose,vv)##########
					commands += self.comgen.command_read_didocico_single(verbose,vv)
					commands += self.comgen.command_write_doco_single(1,1,verbose,vv)
					commands += self.comgen.command_write_doco_single(1,0,verbose,vv)
					commands += self.comgen.command_read_didocico_single(verbose,vv)
				self.dev.send(commands,verbose,vv) 
				read_str_list = self.read_didocico_multiple_bufferonly(2*packet_length,verbose,0)
				self.dev.flush(verbose,vv)
				for i in range(0,packet_length): ##packet length = 32(const)
					count += 1
					di = read_str_list[2*i][0]
					ci_prev = read_str_list[2*i][2]
					ci = read_str_list[2*i+1][2]
					if not (ci == 1 and ci_prev == 1):
						datalist.append(str(di)) #di
						tempdata_str += str(di)
					if count%8 == 0:
						if verbose: print(tempdata_str)
						tempdata_str = ''
					if count%32 == 0:
						if verbose: print('\n\t\t\t\t\t\t\t\t\t')
				if ci == 1 or count > 1024*1024: #cout=1, so cin should be 1 if normal, but 0 when message end.
					if verbose: print(tempdata_str,' - eom')
					break
			## done sequence - 2clk
			i_doco_pairs = [(1,0),(1,1),(1,0),(1,1)]
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			## process data
			f_hit = 0
			return_addrstr = ''.join(addrlist)
			if return_addrstr[0:4] == bin(masterid)[2:].zfill(4): #it is my address!
				f_hit = 1
			elif return_addrstr[0:4] == '0000' : #broadcast address
				f_hit = 1

			## interjection - 6clk
			i_doco_pairs = []
			for i in range(0,6):
				i_doco_pairs.append((1,1))
				i_doco_pairs.append((0,1))
			self.write_doco_multiple(i_doco_pairs,verbose,vv)
			## control bits
			if f_hit :
				#- b1 - don't care #- b2 - EndOfMessage = 1 #- b3 - Acknowledge = 0 (ack) #- b4 - don't care : back to default [1,1]
				self.write_doco_multiple(((0,0),(0,1),(1,0),(1,1),(0,0),(0,1),(1,0),(1,1)),verbose,vv)
			else:
				self.write_doco_single(0,0,verbose,vv)
				self.dev.flush(verbose,vv)
				(di,do,ci,co) = self.read_didocico_single(verbose,vv)
				self.write_doco_multiple(((di,0),(di,1),(di,0)),verbose,vv)
				self.dev.flush(verbose,vv)
				(di,do,ci,co) = self.read_didocico_single(verbose,vv)
				self.write_doco_multiple(((di,0),(di,1),(di,0)),verbose,vv)
				self.dev.flush(verbose,vv)
				(di,do,ci,co) = self.read_didocico_single(verbose,vv)
				self.write_doco_multiple(((di,0),(di,1),(di,0)),verbose,vv)
				self.dev.flush(verbose,vv)
				(di,do,ci,co) = self.read_didocico_single(verbose,vv)
				self.write_doco_multiple(((di,0),(di,1),(1,1)),verbose,vv)
			if verbose: print("\t\t\t- SUCCESS! received message")
			self.dev.flush(verbose,vv)
			break
		return (return_addrstr,datalist) #success

	def tether_message(self,verbose=1,vv=0):
		if vv: verbose=1
		#TODO
		## trasnparently push DIN,CIN to DOUT,COUT
		## while looking for broadcast
		return

	def broadcast_interject(self,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : interject mbus")
		## interjection - N=6 
		self.write_doco_multiple(((1,1), (0,1), (1,1), (0,1), (1,1), (0,1), (1,1), (0,1), (1,1), (0,1), (1,1), (0,1), (1,1)),verbose,vv)
		## control bit - Switch Role, EOM=0 , ACK=0(NACK), IDLE
		self.write_doco_multiple(((1,1), (1,0), (1,1), (0,0), (0,1), (0,0), (0,1), (1,0), (1,1)),verbose,vv)
		return


	def broadcast_enumerate(self,memberid,maxtry=5,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : enumerating member with id=%d"%(memberid))
		if memberid == 0 or memberid == 1:
			raise MbusError("\t\tMbusError : function broadcast_enumerate, memberid %d forbidden\n\n"%(memberid))
			return
		addrstr = '00000000'
		datastr = '0010' + bin(int(memberid))[2:].zfill(4)
		self.write_message_asMaster(addrstr,datastr,maxtry,verbose=verbose,vv=vv)
		self.read_response_asMaster(verbose=verbose,vv=vv)
		if verbose: print("\t\t- SUCCESS! enumeration broadcast sent/received")
		return

	def broadcast_allwake(self,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : waking up all layers")
		addrstr = '00000001'
		datastr = '00010000'
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		if verbose: print("\t\t- SUCCESS! all-wake broadcast sent")
		return

	def broadcast_allsleep(self,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : sleeping up all layers")
		self.broadcast_interject()
		time.sleep(1)
		addrstr = '00000001'
		datastr = '00000000'
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		if verbose: print("\t\t- SUCCESS! all-sleep broadcast sent")
		return

	def selective_sleep(self,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : sleeping up all layers")
		addrstr = '00000001'
		datastr = '00000000000000000000000000000001'+'01000000'+'00000000000000000000'+'1'
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		if verbose: print("\t\t- SUCCESS! all-sleep broadcast sent")
		return

	def broadcast_querydevices(self,nummember=1,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : query devices")
		addrstr = '00000000'
		datastr = '00000000'
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		for i in range(0,nummember):
			self.read_response_asMaster(verbose=verbose,vv=vv)
		if verbose: print("\t\t- SUCCESS! querydevice broadcast sent/received")
		return

	def send_register_write(self,memberid,addr_data_list,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : try reg writing to (member #%d) of"%(memberid),addr_data_list)
		func = '0000'
		if type(memberid) in [type(1) ,type(long(1))]: #integer
			addrstr = bin(memberid)[2:].zfill(4)
		elif type(memberid) == type('1'): #bin string
			addrstr = memberid.zfill(4)
		addrstr += func
		if len(addr_data_list) == 0 :
			raise MbusError('\t\tMbusError : function send_register_write, no message, aborting function call\n\n')
			return
		# compile message
		datastr = ''
		for item in addr_data_list:
			temp_datastr = ''
			for j in range(len(item)):#TODO =hyochan
				if type(item[j]) in [type(1) ,type(long(1))]: #integer
					if j == 0: # address
						temp_addrstr = bin(item[j])[2:]
					else: #data
						temp_datastr = bin(item[j])[2:]
				elif type(item[j]) == type('1'): #string
					temp_datastr += item[j]
			datastr += temp_addrstr.zfill(8) + temp_datastr.zfill(24)
			if len(datastr)%32 != 0:
				raise MbusError('\t\tMbusError : function send_register_write, message %s has length %d, abort\n\n'%(datastr,len(datastr)))
				return
			self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
			datastr = ''
		if verbose: print("\t\t- SUCCESS! register write sent")
		return

	def send_register_read(self,memberid,startaddr,numread,destid,deststartaddr,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : try reg reading from (member #%d from reg addr %d, %d times) and send to (member #%d and store from reg addr %d)"%(memberid,startaddr,numread,destid,deststartaddr))
		func = '0001'
		if type(memberid) in [type(1) ,type(long(1))]: #integer
			addrstr = bin(memberid)[2:].zfill(4)
		elif type(memberid) == type('1'): #bin string
			addrstr = memberid.zfill(4)
		addrstr += func
		datastr = ''
		# compile message
		## - startaddr
		if type(startaddr) in [type(1) ,type(long(1))]: #integer
			datastr += bin(startaddr)[2:].zfill(8)
		elif type(startaddr) == type('1'): #string
			datastr += startaddr.zfill(8)
		## - num read-1
		if type(numread) in [type(1) ,type(long(1))]: #integer
			datastr += bin(numread-1)[2:].zfill(8)
		elif type(numread) == type('1'): #string
			datastr += numread.zfill(8)
		## - dest prefix
		if type(destid) in [type(1) ,type(long(1))]: #integer
			datastr += bin(destid)[2:].zfill(4)
		elif type(destid) == type('1'): #string
			datastr += destid.zfill(4)
		## - dest fuid
		datastr += '0000' #register write
		## - dest startaddr
		if type(deststartaddr) in [type(1) ,type(long(1))]: #integer
			datastr += bin(deststartaddr)[2:].zfill(8)
		elif type(deststartaddr) == type('1'): #string
			datastr += deststartaddr.zfill(8)
		if len(datastr)%32 != 0:
			raise MbusError('\t\tMbusError : function send_register_read, message %s has length %d, abort\n\n'%(datastr,len(datastr)))
			return
		# MBUS
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		(received_addrstr,received_datalist) = self.read_response_asMaster(verbose=verbose,vv=vv)
		# post process
		return_datalist = []
		temp_addr = ''
		temp_data = ''
		if len(received_datalist)%32 != 0:
			raise MbusError('\t\tMbusError : member message length not of multiple of 32')
			return
		for i in range(len(received_datalist)):
			if i%32 <= 7: #addr
				temp_addr += str(received_datalist[i])
			elif i%32 <= 31: #data
				temp_data += str(received_datalist[i])
				if i%32 == 31: #end of data
					return_datalist.append([int(temp_addr,2),temp_data])
					temp_addr = ''
					temp_data = ''
		if verbose: print("\t\t- SUCCESS! register read sent/received")
		return (received_addrstr,return_datalist)

	## Memory API - asMaster
	def send_memory_bulkwrite(self,memberid,startaddr,data_list,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : try mem bulk writing to (member #%d)"%(memberid))
		func = '0010'
		if type(memberid) in [type(1) ,type(long(1))]: #integer
			addrstr = bin(memberid)[2:].zfill(4)
		elif type(memberid) == type('1'): #bin string
			addrstr = memberid.zfill(4)
		addrstr += func
		datastr = ''
		if len(data_list) == 0 :
			raise MbusError('\t\tMbusError : function send_register_write, no message, aborting function call\n\n')
			return
		# compile message
		for item in data_list:
			temp_datastr = ''
			if type(item) in [type(1) ,type(long(1))]:
				temp_datastr += bin(item)[2:]
			elif type(item) == type('1'): #string
				temp_datastr += item
			datastr += temp_datastr.zfill(32)
		if type(startaddr) in [type(1) ,type(long(1))]: #integer
			datastr = bin(startaddr)[2:].zfill(30)+'00' + datastr
		elif type(startaddr) == type('1'): #string
			datastr = startaddr.zfill(30)+'00' + datastr
		if len(datastr)%32 != 0:
			raise MbusError('\t\tMbusError : function send_register_write, message %s has length %d, abort\n\n'%(datastr,len(datastr)))
			return
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		if verbose: print("\t\t- SUCCESS! memory bulk write sent")
		return

	def send_memory_read(self,memberid,startaddr,numread,destid,deststartaddr,verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\tpymbus : try mem reading from (member #%d from mem addr %d, %d times) and send to (member #%d and store from mem addr %d)"%(memberid,startaddr,numread,destid,deststartaddr))
		func = '0011'
		if type(memberid) in [type(1) ,type(long(1))]: #integer
			addrstr = bin(memberid)[2:].zfill(4)
		elif type(memberid) == type('1'): #bin string
			addrstr = memberid.zfill(4)
		addrstr += func
		datastr = ''
		# compile message
		# dest prefix
		if type(destid) in [type(1) ,type(long(1))]: #integer
			datastr += bin(destid)[2:].zfill(4)
		elif type(destid) == type('1'): #string
			datastr += destid.zfill(4)
		# dest fuid
		datastr += '0010' #mem bulk write
		# reserved
		datastr += '0000' #reserved
		# length-1
		if type(numread) in [type(1) ,type(long(1))]: #integer
			#print "case1",bin(numread-1)[2:].zfill(20)
			datastr += bin(numread-1)[2:].zfill(20)
		elif type(numread) == type('1'): #string
			#print "case2"
			datastr += numread.zfill(20)
		# startaddr
		if type(startaddr) in [type(1) ,type(long(1))]: #integer
			datastr += bin(startaddr)[2:].zfill(30)
		elif type(startaddr) == type('1'): #string
			datastr += startaddr.zfill(30)
		datastr += '00' #reserved
		# deststartaddr
		if type(deststartaddr) in [type(1) ,type(long(1))]: #integer
			datastr += bin(deststartaddr)[2:].zfill(30)
		elif type(deststartaddr) == type('1'): #string
			datastr += deststartaddr.zfill(30)
		datastr += '00' #reserved
		if len(datastr)%32 != 0:
			raise MbusError('\t\tMbusError : function send_memory_read, message %s has length %d, abort\n\n'%(datastr,len(datastr)))
			return
		# MBUS
		self.write_message_asMaster(addrstr,datastr,verbose=verbose,vv=vv)
		(received_addrstr,received_datalist) = self.read_response_asMaster(verbose=verbose,vv=vv)
		# post process
		return_datalist = []
		temp_data = ''
		for i in range(0,len(received_datalist)):
			if i%32 <= 31: #data
				temp_data += str(received_datalist[i])
				if i%32 == 31: #end of data
					return_datalist.append([temp_data])
					temp_data = ''
		if verbose: print("\t\t- SUCCESS! memory read sent/received")
		return (received_addrstr,return_datalist)

	def send_memory_streamwrite(self,verbose=1,vv=0):
		if vv: verbose=1
		#TODO
		return

class _MBUS_FT232H_command_generator():
	def __init__(self):
		return

	def command_write_doco_single(self,dout,cout,verbose=1,vv=0):
		if vv: verbose=1
		if vv: print("\t\t\t\t- command compile, write_doco", "[c1(dout),c3(cout)] = [%d,%d]"%(dout,cout))
		commands = ''
		i_dout = int(dout)
		i_cout = int(cout)
		commands += '\x82'
		commands += chr(0b000000+i_cout*2**3+i_dout*2**1)
		commands += '\x1F'
		return commands*command_width

	def command_read_didocico_single(self,verbose=1,vv=0):
		if vv: verbose=1
		if vv: print("\t\t\t\t- command compile, read_dococico")
		commands = '\x83'
		return commands

class _MBUS_FT232H_device():
	def __init__(self, newinstance=1,ftID=0, verbose=1,vv=0):
		if vv: verbose=1
		if verbose: print("\t\t\t- ft232h : Listing connected ftd2xx device (by Serial#):", ftd2xx.listDevices(ft.OPEN_BY_SERIAL_NUMBER))
		if verbose: print("\t\t\t- ft232h : Listing connected ftd2xx device (by description):", ftd2xx.listDevices(ft.OPEN_BY_DESCRIPTION))
		if verbose: print("\t\t\t- ft232h : Opening device by given ftID:", ftID, "(default=0)")
		self.dev = ftd2xx.open(ftID)
		if newinstance:
			self._bringup_configmode(verbose,vv)
			self._bringup_syncmpsse(verbose,vv)
			self._bringup_configmpsse(verbose,vv)
		return

	def __del__(self):
		self.dev.close()
		return

	def _bringup_configmode(self, verbose=1, vv=0):
		if vv: verbose=1
		if verbose: print("\t\t\t- ft232h : Bringing up FT232H configuration")
		# Reset the FT232H
		if vv: print("\t\t\t\t- resetting FT232H")
		self.dev.resetDevice()
		# Purge USB receive buffer ... Get the number of bytes in the FT232H receive buffer and then read them
		if vv: print("\t\t\t\t- flushing FT232H read buffer")
		dwNumInputBuffer = self.dev.getQueueStatus()
		if (dwNumInputBuffer > 0):
			self.dev.read(dwNumInputBuffer)
		if vv: print("\t\t\t\t- setting up USB communication / FT232H mode=MPSSE")
		self.dev.setUSBParameters(65536, 65535) # Set USB request transfer sizes
		self.dev.setChars(False, 0, False, 0) 	# Disable event and error characters
		self.dev.setTimeouts(5000, 5000)	# Set the read and write timeouts to 5 seconds
		#self.dev.setLatencyTimer(16)		# Keep the latency timer at default of 16ms
		self.dev.setLatencyTimer(4)		# Set the latency timer at default of 1ms
		self.dev.setBitMode(0x0, 0x00)		# Reset the mode to whatever is set in EEPROM
		self.dev.setBitMode(0x0, 0x02)		# Enable MPSSE mode
		return

	def _bringup_syncmpsse(self, verbose=1, vv=0):
		if vv: verbose=1
		if verbose: print("\t\t\t- ft232h : Synchronizing MPSSE")
		commands = "\xAA"	#0xAA = bad command
		self.send(commands,verbose,vv)
		read_str = self.read(2,verbose,vv)
		if read_str == "\xFA"+"\xAA" :
			if verbose: print("\t\t\t- ft232h : (1/2) SUCCESS! synchronized MPSSE with bad command 0xAA")
		else:
			if verbose: print("\t\t\t- ft232h : (1/2) failed synchronization")
			raise MbusError
		commands = "\xAB"	#0xAA = bad command
		self.send(commands,verbose,vv) #0xAB = bad command
		read_str = self.read(2,verbose,vv)
		if read_str == "\xFA"+"\xAB" :
			if verbose: print("\t\t\t- ft232h : (2/2) SUCCESS! synchronized MPSSE with bad command 0xAB")
		else:
			if verbose: print("\t\t\t- ft232h : (2/2) failed synchronization")
			raise MbusError
		return

	def _bringup_configmpsse(self, verbose=1, vv=0):
		if vv: verbose=1
		if verbose: print("\t\t\t- ft232h : Configuring MPSSE (Multi-Protocol Synchornonous Serial Engine) to MBUS")
		if verbose: print("\t\t\t\t[MISC setting]")
		commands = ""
		commands += "\x8B"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tEnable clock divide-by-5 for 60Mhz master clock")
		commands += "\x8D"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tDisable 3 phase data clocking, that makes data hold longer so it's valid on both clock edges. for I2C")
		commands += "\x97"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tDisable adaptive clocking")
		commands += "\x9E"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tDrive-zero mode on the lines used for I2C ...")
		commands += "\x00"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t...Disabled for lower port AD 0-7")
		commands += "\x00"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t...Disabled for upper port AC 0-7")
		commands += "\x85"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tInternal loopback is off")
		self.send(commands,verbose,vv)
		if verbose: print("\t\t\t\t[Clock setting to 1.2MHz]")
		commands = ""
		commands += "\x86"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tSet clock divisor = ((1+256*valueH+valueL)*2)")
		commands += "\x02"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t....valueL=2")
		commands += "\x00"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t....valueH=0 ... div by 10 ... 1.2MHz")
		self.send(commands,verbose,vv)
		if verbose: print("\t\t\t\t[Pin map c0=din(i), c1=dout(O), c2=cin(i), c3=cout(O)] perspective to Master")
		commands = ""
		commands += "\xF0"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tSet AD 0-7 values for pins that are output (not used)")
		commands += "\x00"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t...all as zeros (not used)")
		commands += "\x00"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t...no pins are outputs (not used)")
		self.send(commands,verbose,vv)
		commands = ""
		commands += "\x82"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\tSet AC 0-7 values for pins that are output")
		commands += "\x06"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t...[1]=dout, [3]=cout are ones")
		commands += "\x06"
		if vv: print("\t\t\t\t"+hex(ord(commands[-1]))+"\t...[1]=dout, [3]=cout are outputs")
		self.send(commands,verbose,vv)
		return

	def send(self,commands='',verbose=1,vv=0):
		if vv: verbose=1
		if vv: print("\t\t\t\tft232h.send : sending following command", ", length :", len(commands))
		i_iter = (len(commands))/16 + int((len(commands))%16 > 0)
		for i in range(i_iter):
			if i == i_iter-1:
				if vv: print("\t\t\t\t->"+' '.join([hex(ord(x))[2:].zfill(2) for x in commands[16*i:]]))
			else:
				if vv: print("\t\t\t\t->"+' '.join([hex(ord(x))[2:].zfill(2) for x in commands[16*i:16*(i+1)]]))
		write_len = self.dev.write(commands)
		if write_len != len(commands):
			if verbose: print("\t\t\t\t- Failed writing, timeout")
			raise MbusError
		else:
			if vv: print("\t\t\t\t- SUCCESS! writing")
		return write_len

	def read(self,length=2,verbose=1,vv=0):
		if vv: verbose=1
		if vv: print("\t\t\t\tft232h.read : reading device for length =", length)
		tries = 0
		read_len = self.dev.getQueueStatus()
		if vv: print("\t\t\t\t- data len in read buffer = %d"%(read_len))
		while (read_len < length and tries < 100):
			read_len = self.dev.getQueueStatus()
			tries += 1
			time.sleep(0.01)
		if (tries < 100):
			read_str = self.dev.read(length)
			i_iter = (len(read_str))/16 + int((len(read_str))%16 > 0)
			for i in range(i_iter):
				if i == i_iter-1:
					if vv: print("\t\t\t\t->"+' '.join([hex(ord(x))[2:].zfill(2) for x in read_str[16*i:]]))
				else:
					if vv: print("\t\t\t\t->"+' '.join([hex(ord(x))[2:].zfill(2) for x in read_str[16*i:16*(i+1)]]))
			if vv: print("\t\t\t\t- SUCCESS! reading")
		else:
			if verbose: print("\t\t\t\t- Failed reading, timeout")
			raise MbusError
		return read_str

	def flush(self,verbose=1,vv=0):
		if vv: verbose=1
		if vv: print("\t\t\t\tft232h.flush : flushing read buffer")
		read_len = self.dev.getQueueStatus()
		if vv: print("\t\t\t\t- read buffer has %d data...  flushing"%(read_len))
		if (read_len > 0):
			self.dev.read(read_len)
		if vv: print("\t\t\t\t- SUCCESS! flushing")
		return



class Error(Exception):
	pass

class MbusError(Error):
	def __init__(self,expression):
		print(expression)
