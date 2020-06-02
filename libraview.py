
import saleae

import datetime
import time
import array
import os
from itertools import * 
import traceback
import multiprocessing as mp
import subprocess as sp
import glob

import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
import natsort

import cv2

plt.ion()

class libraview():
	def __init__(self):
		self.fig1 = None
		self.fig2 = None
		return

	def stream(self,numstream=float('inf'),maxcode=2**10,zoom=1,dpi=96,dgain=1,pedestal=0,offset=0,cmap='gray',source=0,basepath=r'.\04_captures\stream',store=0,noraw=1,noshow=0,M=0,animate=0,animate_interval=1000,color=0,denoise=0,wb=0,wb_gain=[1.0,0.8,1.7],showlast=0,md=0):
		i = 0
		date = datetime.datetime.now().strftime("%Y%m%d")
		hour = datetime.datetime.now().strftime("%H%M%S")
		return_str = []
		while True:
			try:
				if (numstream <= i-1 and M) or (numstream <= i and not M): break
				elif source == 0:
					if i < numstream and M:
						print("\tlibraView : iter %d - capture"%(i+1))
						hour = datetime.datetime.now().strftime("%H%M%S")
						filename = r'\%s_%s_%d.bin'%(date,hour,(i+1))
						p1 = mp.Process(target=self.capture_img,args=(basepath+filename,)) #p1 = capture from Saleae
						p1.start()
					elif i < numstream and not M:
						print("\tlibraView : iter %d - capture"%(i))
						hour = datetime.datetime.now().strftime("%H%M%S")
						filename = r'\%s_%s_%d.bin'%(date,hour,(i))
						self.capture_img(basepath+filename)
						prev_date = date
						prev_hour = hour
					if (i >= 1 and M) or (i >= 0 and not M): 
						print("\tlibraView : iter %d - process and show"%(i))
						## processing with .exe
						filename = r'\%s_%s_%d.bin'%(prev_date,prev_hour,(i))
						if showlast : 
							p = sp.Popen(['VIMv1_process_MD.exe',basepath+filename],stdout=sp.PIPE)
							(stdouttext,stderrtext)=p.communicate()
							temp_line = stdouttext.split('\n')[-8:-2]
							return_str = temp_line[:]
							print('\n'.join(temp_line))
						else : 
							p = sp.Popen(['VIMv1_process_MD.exe',basepath+filename])
							p.communicate()
						if noraw : os.remove(basepath+filename)
						listofraw = glob.glob(basepath+filename+'_*')
						listofraw = natsort.natsorted(listofraw)
						N = sum([os.stat(x).st_size != 0 and len(x.split('.')[-1].split('_')) == 2 for x in listofraw])
						if not noshow and not animate and not md:
							## load and show
							for j in range(N) if not showlast else [N-1]:
								print("\t\tlibraView : showing %d-%d image"%(i,j+1))
								pfilename = r'\%s_%s_%d.bin_%d'%(prev_date,prev_hour,(i),j+1)
								img_array = self.load_grayimg(basepath+pfilename,source=0)[0]
								hfilename = r'\%s_%s_%d.bin_hist_%d'%(prev_date,prev_hour,(i),j+1)
								hist_array = self.load_grayhist(basepath+hfilename)
								figpath = basepath+'_save'
								figname = r'\%s_%s_%d_%d.png'%(prev_date,prev_hour,(i),j+1)
								self.draw_img(img_array,hist_array,maxcode,zoom,dpi,dgain,pedestal,offset,'%d-%d image'%(i,j+1),store,figpath+figname,color,denoise,wb,wb_gain)
								plt.pause(0.3)
								#plt.pause(2)
						elif not noshow and animate and not md:
							loop_img_array = []
							## load
							for j in range(N):
								print("\t\tlibraView : showing %d-%d image"%(i,j+1))
								pfilename = r'\%s_%s_%d.bin_%d'%(prev_date,prev_hour,(i),j+1)
								img_array = self.load_grayimg(basepath+pfilename,source=0)[0]
								loop_img_array.append(img_array[:])
							figpath = basepath+'_save'
							figname = r'\%s_%s.mp4'%(prev_date,prev_hour)
							self.animate_grayimg(np.array(loop_img_array),maxcode,zoom,dpi,dgain,pedestal,offset,animate_interval,store,figpath+figname,color,denoise,wb,wb_gain)
						elif not noshow and md:
							## MD behavior
							filesize = [os.stat(x).st_size for x in listofraw if len(x.split('.')[-1].split('_')) == 2]
							vga_index = filesize.index(max(filesize))
							prev_md_data = []
							post_md_data = []
							for j in range(N):
								pfilename = r'\%s_%s_%d.bin_%d'%(prev_date,prev_hour,(i),j+1)
								if j < vga_index: #pre_MD
									img_array = self.load_grayimg(basepath+pfilename,source=0)[0]
									prev_md_data.append(img_array[:])
								elif j == vga_index: #vga
									img_array = self.load_grayimg(basepath+pfilename,source=0)[0]
									vga_data = img_array[:]
								elif j > vga_index: #post_MD
									img_array = self.load_grayimg(basepath+pfilename,source=0)[0]
									post_md_data.append(img_array[:])
								else: pass
							figpath = basepath+'_save'
							figname = r'\%s_%s_%d.png'%(prev_date,prev_hour,(i))
							self.draw_md(prev_md_data,vga_data,post_md_data,maxcode,zoom,dpi,dgain,pedestal,offset,'%s_%s_%d'%(prev_date,prev_hour,i),store,figpath+figname,color,denoise,wb,wb_gain)
							plt.pause(0.3)
						if noraw: 
							if not showlast : print('\t\tremoving files :',','.join([x.split('\\')[-1] for x in listofraw]))
							[os.remove(x) for x in listofraw]
					if i < numstream and M:
						p1.join()
						print('\t\t- snooping joined')
					elif i < numstream and not M:
						print('\t\t- snooping joined')
					i += 1
				prev_date = date
				prev_hour = hour
			except KeyboardInterrupt: 
				return
			except Exception as e:	
				traceback.print_exc()
				time.sleep(0.1)
				i += 1
				pass #redo
		return return_str

	def draw_md(self,prev_md_data,vga_data,post_md_data,maxcode=2**12,zoom=1,dpi=96,dgain=1,pedestal=0,offset=0,plotname='',store=0,path='',color=0,denoise=0,wb=0,wb_gain=[1.0,1.0,1.8]):
		t = time.time()
		print("\t\tlibraView : drawing images of MD capture")
		len_premd = min(len(prev_md_data),3)
		len_postmd = min(len(post_md_data),6)
		newdpi = dpi/zoom
		#matplotlib
		if self.fig1 == None : self.fig1 = plt.figure()
		if self.fig2 == None : self.fig2 = plt.figure()
		## draw MD frames
		self.fig1.clear()
		#self.fig1.set_size_inches(15,10,forward=True)
		## draw MD frames - draw pre-MD
		for i in range(0,3):
			if i+1 > len_premd : pass
			else: 
				ax = self.fig1.add_subplot(3,3,3-i)
				ax.set_title("pre-motion frame: "+plotname+" - %d"%(i))
				img_data_slice = prev_md_data[-1*i-1] - offset
				img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_GRAY2BGR)
				img_data_slice = (np.minimum(((img_data_slice)*dgain)+pedestal,maxcode-1)*(256.0/maxcode)).astype(np.uint8)
				ax.imshow(img_data_slice,interpolation=None)
		## draw MD frames - draw post-MD
		for i in range(0,6):
			if i+1 > len_postmd : pass
			else: 
				ax = self.fig1.add_subplot(3,3,3+i+1)
				ax.set_title("post-motion frame: "+plotname+" - %d"%(i+4))
				img_data_slice = post_md_data[i] - offset
				img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_GRAY2BGR)
				img_data_slice = (np.minimum(((img_data_slice)*dgain)+pedestal,maxcode-1)*(256.0/maxcode)).astype(np.uint8)
				ax.imshow(img_data_slice,interpolation=None)
		## draw VGA frame
		y = float(len(vga_data))
		x = len(vga_data[0])
		self.fig2.clear()
		#self.fig2.set_size_inches(x/newdpi,y/newdpi,forward=True)
		ax1 = self.fig2.add_subplot(1,1,1)
		ax1.set_title("motion VGA frame: "+plotname+" - %d"%(3))
		img_data_slice = vga_data-offset
		if color : img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_BAYER_RG2BGR)
		else : img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_GRAY2BGR)
		if wb and color : 
			img_data_slice = img_data_slice.astype(float)
			img_data_slice[:,:,0] *= wb_gain[0] #adjust blue gain
			img_data_slice[:,:,1] *= wb_gain[1] #adjust green gain
			img_data_slice[:,:,2] *= wb_gain[2] #adjust red gain
		img_data_slice = (np.minimum(((img_data_slice)*dgain)+pedestal,maxcode-1)*(256.0/maxcode)).astype(np.uint8)
		if denoise: img_data_slice = cv2.fastNlMeansDenoisingColored(img_data_slice,None,3,3,3,7)
		ax1.imshow(img_data_slice,interpolation=None)
		print("\t\t>image drawing : time = %.1f sec"%(time.time()-t))
		if store:
			print("\t\tlibraView : saving image with name %s"%(plotname))
			self.fig1.savefig('.'.join(path.split('.')[:-1])+'_MD.png')	
			self.fig2.savefig('.'.join(path.split('.')[:-1])+'_VGA.png')	
		plt.show()
		plt.pause(0.05)
		return

	def draw_img(self,img_data,hist_data=None,maxcode=2**12,zoom=1,dpi=96,dgain=1,pedestal=0,offset=0,plotname='',store=0,path='',color=0,denoise=0,wb=0,wb_gain=[1.0,1.0,1.8]):
		t = time.time()
		y = float(len(img_data))
		x = len(img_data[0])
		print("\t\tlibraView : drawing image with x=%d,y=%d,maxcode=%d,zoom=%d,dpi=%d"%(x,y,maxcode,zoom,dpi))
		newdpi = dpi/zoom
		#matplotlib
		if self.fig1 == None : self.fig1 = plt.figure()
		if self.fig2 == None and (type(hist_data) == type(np.array([])) and hist_data.all() != None): self.fig2 = plt.figure()
		self.fig1.clear()
		#self.fig1.set_size_inches(x/newdpi,y/newdpi,forward=True)
		ax1 = self.fig1.add_subplot(1,1,1)
		ax1.set_title(plotname)
		img_data_slice = img_data-offset
		if color : img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_BAYER_RG2BGR)
		else : img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_GRAY2BGR)
		if wb and color : 
			img_data_slice = img_data_slice.astype(float)
			img_data_slice[:,:,0] *= wb_gain[0] #adjust blue gain
			img_data_slice[:,:,1] *= wb_gain[1] #adjust green gain
			img_data_slice[:,:,2] *= wb_gain[2] #adjust red gain
		img_data_slice = (np.minimum(((img_data_slice)*dgain)+pedestal,maxcode-1)*(256.0/maxcode)).astype(np.uint8)
		if denoise: img_data_slice = cv2.fastNlMeansDenoisingColored(img_data_slice,None,3,3,3,7)
		#ax1.imshow(img_data_slice,interpolation=None,norm=mpl.colors.NoNorm(vmin=0,vmax=255))
		ax1.imshow(img_data_slice,interpolation=None)
		print("\t\t>image drawing : time = %.1f sec"%(time.time()-t))
		if store:
			print("\t\tlibraView : saving image with name %s"%(plotname))
			self.fig1.savefig(path)	
		if type(hist_data) == type(np.array([])) and hist_data.all() != None:
			t = time.time()
			self.fig2.clear()
			ax2 = self.fig2.add_subplot(1,1,1)
			ax2.plot(range(0,4096),hist_data)
			print("\t\t>hist drawing : time = %.1f sec"%(time.time()-t))
		plt.show()
		plt.pause(0.05)
		return

	def animate_grayimg(self,img_data,maxcode=2**12,zoom=1,dpi=96,dgain=1,pedestal=0,offset=0,animate_interval=1000,store=0,path='',color=0,denoise=0,wb=0,wb_gain=[1.0,1.0,1.8]):
		t = time.time()
		y = float(len(img_data[0]))
		x = len(img_data[0][0])
		print("\t\tlibraView : animate image with x=%d,y=%d,maxcode=%d,zoom=%d,dpi=%d"%(x,y,maxcode,zoom,dpi))
		newdpi = dpi/zoom
		#matplotlib
		if self.fig1 == None : self.fig1 = plt.figure()
		self.fig1.clear()
		#self.fig1.set_size_inches(x/newdpi,y/newdpi,forward=True)
		ax1 = self.fig1.add_subplot(1,1,1)
		ims = []
		for i in range(0, len(img_data)):
			img_data_slice = img_data[i] - offset
			if color : img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_BAYER_RG2BGR)
			else : img_data_slice = cv2.cvtColor(img_data_slice, cv2.COLOR_GRAY2BGR)
			if wb and color : 
				img_data_slice = img_data_slice.astype(float)
				img_data_slice[:,:,0] *= wb_gain[0] #adjust blue gain
				img_data_slice[:,:,1] *= wb_gain[1] #adjust green gain
				img_data_slice[:,:,2] *= wb_gain[2] #adjust red gain
			img_data_slice = (np.minimum(((img_data_slice)*dgain)+pedestal,maxcode-1)*(256.0/maxcode)).astype(np.uint8)
			if denoise: img_data_slice = cv2.fastNlMeansDenoisingColored(img_data_slice,None,3,3,3,7)
			ims.append([plt.imshow(img_data_slice,interpolation=None,norm=mpl.colors.NoNorm(vmin=0,vmax=255),animated=True)])
		ani = animation.ArtistAnimation(self.fig1, ims, interval=animate_interval, blit=True)#, repeat_delay=100)
		if store:
			print("\t\tlibraView : saving animation")
			ani.save(path)
		plt.show()
		plt.pause(0.05)
		return

	def load_grayhist(self,filename):
		if os.path.exists(filename):
			print("\t\tlibraView : reading histogram dump")
			hist_data = array.array('L')
			print('\t\t- opening file : %s'%filename)
			hist_data.fromfile(open(filename,'rb'), os.path.getsize(filename) // hist_data.itemsize)
			return np.fromiter(hist_data,dtype=int)
		else: return None

	def load_grayimg(self,filename,source=0,N=1):	
		print("\t\tlibraView : reading binary dump")
		t = time.time()
		# process data
		bin_data = array.array('H')
		print('\t\t- opening file : %s'%filename)
		bin_data.fromfile(open(filename,'rb'), os.path.getsize(filename) // bin_data.itemsize)
		if source == 1: #from saleae dump directly
			return_data = self._load_grayimg_filter(bin_data,N)
		elif source == 0: #from c-processed output file
			numrow = bin_data[-1]
			numcol = bin_data[-2]
			return_data = [np.array(np.array_split(np.fromiter(bin_data[:-2],dtype=np.uint16),numrow))]
		print("\t\t>reading : time = %.1f sec"%(time.time()-t))
		return return_data
		
	def _load_grayimg_filter(bin_data,N=1):
		t = time.time()
		ch_map = {	'clk':0,
				'd0' :1,
				'd1' :2,
				'd2' :4,
				'd3' :5,
				'd4' :6,
				'd5' :7,
				'd6' :8,
				'd7' :9,
				'd8' :10,
				'd9' :11,
				'd10' :12,
				'd11' :13,
				'hsync' : 14,
				'vsync' : 15
			}
		bitorderlist = [15-ch_map['d'+str(x)] for x in range(0,12)[::-1]]
		vsync_index = ch_map['vsync']
		vsync_thres = 2**vsync_index
		hsync_index = ch_map['hsync']
		hsync_thres = 2**hsync_index
		clk_index = ch_map['clk']
		clk_thres = 2**clk_index
		for i in range(N):
			print('\t\t- loading %d-th/%d dataset from binary dump :'%(i+1,N),time.time() - tt)
			tt = time.time()
			vsync_data = dropwhile(lambda x: not x/vsync_thres%2, bin_data)
			if N > 1: (bin_data,vsync_data) = tee(vsync_data,2)
			vsync_data = tuple(takewhile(lambda x: x/vsync_thres%2, vsync_data))
			if N > 1: bin_data = tuple(dropwhile(lambda x: x/vsync_thres%2, bin_data))
			print('\t\t- data length = ',len(bin_data))
			clk_data_xor = imap(lambda x,y: not x/clk_thres%2 and y/clk_thres%2,islice(vsync_data,0,None),islice(vsync_data,1,None))
			result_data = compress(islice(vsync_data,1,None),clk_data_xor)
			def f(x) : 
				## generic
				#temp_x = bin(x)[2:]
				#return int(''.join([temp_x[y] for y in bitorderlist]),2)
				## specific to saleae with dead ch3
				temp_x = x%8192
				return temp_x/16*8+temp_x%8
			img_data = imap(f,result_data)
			img_data = tuple(img_data)
			print('\t\t- creating img_data :',time.time() - tt)
			## get numcol
			tt = time.time()
			hsync = dropwhile(lambda x : not x/hsync_thres%2, vsync_data)
			hsync = tuple(takewhile(lambda x : x/hsync_thres%2, hsync))
			len_hsync = len(hsync)
			hsync_clk = imap(lambda x,y: not x/clk_thres%2 and y/clk_thres%2,islice(hsync,0,len_hsync-2),islice(hsync,1,None))
			numcol=sum(hsync_clk)
			len_img = len(img_data)
			numrow=len_img/numcol
			print('\t\t- getting num row :',time.time() - tt)
			return_array.append(np.array(np.array_split(np.fromiter(img_data,dtype=float),numrow)))
			#return_array.append(np.array(np.array_split(np.fromiter(img_data,dtype=np.uint32),numrow)))
		print("\t\t>loading : time = %.1f sec"%(time.time()-t))
		return return_array

	def capture_img(self,filename):	
		t = time.time()
		print("\t\tlibraView : snooping image with Saleae")
		if os.path.exists(filename): os.remove(filename)
		sal = saleae.Saleae()
		sal.capture_start_and_wait_until_finished()
		sal.export_data2(os.path.abspath(filename),[0,1,2],None,None,'binary') #binary is fastest
		while not os.path.exists(filename) or not (os.path.getsize(filename) > 1000) or not sal.is_processing_complete(): #wait
			time.sleep(0.5)
		time.sleep(5)
		print("\t\t>snooping : time = %.1f sec"%(time.time()-t))
		time.sleep(1)
		return
