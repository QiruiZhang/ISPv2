from colorama import Fore, Back, Style
from colorama import init
from pandas import *
import datetime
import time
import libra
import itertools
import math
import numpy as np
import matplotlib
from matplotlib import ticker
import matplotlib.pyplot as plt

# Import the email modules we'll needb
#from email.mime.text import MIMEText
# Import smtplib for the actual sending function
import smtplib
from_usr = 'jingcheng.wang.program@gmail.com'
password = 'pythonAutoSend'
to_usr = 'w751611422@gmail.com'

allow_email_alert = False
run_mainMem_test = False     #skipping the main memory test
run_detail_test = True      #skipping the whole memory test and directly generate report
allow_mainMem_error = True  #continue testing other memory even though there are error bits in main memory
Date = datetime.datetime.now().strftime("%m%d")
hour = datetime.datetime.now().strftime("%H%M")

chipID   = str(raw_input("\n\tchipID?  :   "))
VDD_core = str(raw_input("\n\tVDD_core?:   "))
VDD_mem  = str(raw_input("\n\tVDD_mem ?:   "))
osc_sd   = 0x19
osc_div  = 2


allow_email_alert &= run_detail_test

def heatmap(data, row_labels, col_labels, ax=None,
            cbar_kw={}, cbarlabel="", **kwargs):
    """
    Create a heatmap from a numpy array and two lists of labels.

    Parameters
    ----------
    data
        A 2D numpy array of shape (N, M).
    row_labels
        A list or array of length N with the labels for the rows.
    col_labels
        A list or array of length M with the labels for the columns.
    ax
        A `matplotlib.axes.Axes` instance to which the heatmap is plotted.  If
        not provided, use current axes or create a new one.  Optional.
    cbar_kw
        A dictionary with arguments to `matplotlib.Figure.colorbar`.  Optional.
    cbarlabel
        The label for the colorbar.  Optional.
    **kwargs
        All other arguments are forwarded to `imshow`.
    """

    if not ax:
        ax = plt.gca()

    # Plot the heatmap
    im = ax.imshow(data, **kwargs)

    # Create colorbar
    cbar = ax.figure.colorbar(im, ax=ax, **cbar_kw)
    cbar.ax.set_ylabel(cbarlabel, rotation=-90, va="bottom")

    # We want to show all ticks...
    ax.set_xticks(np.arange(data.shape[1]))
    ax.set_yticks(np.arange(data.shape[0]))
    # ... and label them with the respective list entries.
    ax.set_xticklabels(col_labels)
    ax.set_yticklabels(row_labels)

    # Let the horizontal axes labeling appear on top.
    ax.tick_params(top=True, bottom=False,
                   labeltop=True, labelbottom=False)

    # Rotate the tick labels and set their alignment.
    plt.setp(ax.get_xticklabels(), rotation=-30, ha="right",
             rotation_mode="anchor")

    # Turn spines off and create white grid.
    for edge, spine in ax.spines.items():
        spine.set_visible(False)

    ax.set_xticks(np.arange(data.shape[1]+1)-.5, minor=True)
    ax.set_yticks(np.arange(data.shape[0]+1)-.5, minor=True)
    ax.grid(which="minor", color="w", linestyle='-', linewidth=3)
    ax.tick_params(which="minor", bottom=False, left=False)

    return im, cbar


def annotate_heatmap(im, data=None, valfmt="{x:.2f}",
                     textcolors=["black", "white"],
                     threshold=None, **textkw):
    """
    A function to annotate a heatmap.

    Parameters
    ----------
    im
        The AxesImage to be labeled.
    data
        Data used to annotate.  If None, the image's data is used.  Optional.
    valfmt
        The format of the annotations inside the heatmap.  This should either
        use the string format method, e.g. "$ {x:.2f}", or be a
        `matplotlib.ticker.Formatter`.  Optional.
    textcolors
        A list or array of two color specifications.  The first is used for
        values below a threshold, the second for those above.  Optional.
    threshold
        Value in data units according to which the colors from textcolors are
        applied.  If None (the default) uses the middle of the colormap as
        separation.  Optional.
    **kwargs
        All other arguments are forwarded to each call to `text` used to create
        the text labels.
    """

    if not isinstance(data, (list, np.ndarray)):
        data = im.get_array()

    # Normalize the threshold to the images color range.
    if threshold is not None:
        threshold = im.norm(threshold)
    else:
        threshold = im.norm(data.max())/2.

    # Set default alignment to center, but allow it to be
    # overwritten by textkw.
    kw = dict(horizontalalignment="center",
              verticalalignment="center")
    kw.update(textkw)

    # Get the formatter in case a string is supplied
    if isinstance(valfmt, str):
        valfmt = matplotlib.ticker.StrMethodFormatter(valfmt)

    # Loop over the data and create a `Text` for each "pixel".
    # Change the text's color depending on the data.
    texts = []
    for i in range(data.shape[0]):
        for j in range(data.shape[1]):
            kw.update(color=textcolors[int(im.norm(data[i, j]) > threshold)])
            text = im.axes.text(j, i, valfmt(data[i, j], None), **kw)
            texts.append(text)

    return texts

def memory_compare(chip, filename='design_tb_0.hex',memberid=2,startaddr=0,verbose=1,vv=0):
	print(Fore.YELLOW + '- libra2 : main PROGRAM write')
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
        ifile.close()
	chip.mbus.send_memory_bulkwrite(memberid,startaddr,datalist,verbose=verbose,vv=vv)
	
        ofile_memread= open('memread.log','w')
	(fuid,returned_datalist)=chip.mbus.send_memory_read(2,startaddr,len(datalist),1,0,verbose=1,vv=0)
	returned_datalist = list(itertools.chain(*returned_datalist))
	returned_datalist = [int(s,2) for s in returned_datalist]

        correct = False
        addrlist=[]
        errorlist=[]
        errorbank=[]
	if datalist == returned_datalist[1:] :
		print "Yei ^^"
                correct=True
	else:
		print(Fore.RED + 'Nei :(')
		print(Style.RESET_ALL)
                correct=False

                for i in range(len(datalist)):
                    if datalist[i] != returned_datalist[i+1]:
                        addrlist.append(i)
                        bank = i / 1024
                        if bank not in errorbank:
                            errorbank.append(bank)
                        errorlist.append((hex(i*4), bin(datalist[i])[2:].zfill(32), bin(returned_datalist[i+1])[2:].zfill(32),bin(datalist[i]^returned_datalist[i+1])[2:].zfill(32))) 
        
        ofile_memread.close()
	ofile_memwrite.close()

        return correct, addrlist, errorbank, errorlist

def send_email(from_usr,password, to_usr, msg):
    #server = smtplib.SMTP('smtp.gmail.com',587)
    #server.starttls()
    server = smtplib.SMTP_SSL('smtp.gmail.com',465)
    server.login(from_usr,password)
    server.sendmail(from_usr, to_usr, msg)
    server.quit()
    return

def block_map(i):
    block_name = '' 
    block_num = 0
    if i == 0:
        block_name = 'IMG_MinMax'
        block_num = i
    elif 0 < i <= 8: 
        block_name = 'IMG_CD'
        block_num = i-1
    elif 8 < i <= 11: 
        block_name = 'IMG_REF'
        block_num = i-9
    elif 11 < i <= 66: 
        block_name = 'IMG_COMP'
        block_num = i-12
    elif 66 < i <= 146: #67~146
        block_name = 'NE_Shared'
        block_num = i-67
    elif 146 < i <= 150: 
        block_name = 'NE_Weight'
        block_num = i-147
    elif 150 < i <= 152: 
        block_name = 'NE_Instr'
        block_num = i-151
    elif 152 < i <= 156: 
        block_name = 'NE_Local'
        block_num = i-153
    elif 156 < i <= 220: 
        block_name = 'NE_Accum'
        block_num = i-157
    elif 220 < i <= 221: 
        block_name = 'NE_Bias'
        block_num = i-221
    elif 221 < i <= 222: 
        block_name = 'H264'
        block_num = i-222
    return block_name, block_num

IMG_Quality = True
NE_Quality = True
IMG_Usable = True
#NE_Usable = True
H264_Usable = True

mainMem_error = 0
main_errorbank = []
start = time.time()
if run_detail_test:
    chip = libra.libra()
    #chip.boot()
    chip.boot(filename='./01_maincodes/design_tb_20.hex',osc_sd=osc_sd,osc_div=osc_div,verbose=1,vv=0)
    ##debug CLK
    chip.write('debug',[3,7]) #1:h264 2:tx 3:rx 4:fls 5:ne 6:vga 7:clk_lc
    
    #Main Memory Test
    if run_mainMem_test:
        correct = True
        errorAddr = []
        errorlist = []
        
        (tmp_correct, tmp_addrlist, tmp_errorbank, tmp_errorlist) = memory_compare(chip, filename='./01_maincodes/Main_SRAM_testPattern.hex',startaddr=0)
        correct &= tmp_correct
        errorAddr += tmp_addrlist
        main_errorbank += tmp_errorbank
        errorlist.append(tmp_errorlist)
        
        (tmp_correct, tmp_error_cnt, tmp_errorbank, tmp_errorlist) = memory_compare(chip, filename='./01_maincodes/Main_SRAM_testPattern_C.hex',startaddr=0)
        correct &= tmp_correct
        errorAddr += tmp_addrlist
        main_errorbank += tmp_errorbank
        errorlist.append(tmp_errorlist)
        
        if not correct:
            mainMem_error = len(errorAddr)
            msg = 'Subject: Main Memory has {} error word\n'.format(mainMem_error)
            msg += 'error banks: {} \n'.format(main_errorbank)
            msg += "addr\torigin\tactual\txor\n"
            
            if allow_email_alert:
                send_email(from_usr, password, to_usr, msg)

            for item in errorlist:
                msg += "{}\t{}\t{}\t{}\n".format(item[0],item[1],item[2],item[3])
            
            filename = "./05_memorytest/{}_MainMem_{}_{}_{}.log".format(chipID, VDD_core, VDD_mem, Date)
            ofile = open(filename,'w')
            ofile.write(msg)
            ofile.close()
            if not allow_mainMem_error:
                exit()
    
    #Load M0 to test all other MEM
    chip.write_prog_mem(filename='./01_maincodes/SRAM_test_detail2.hex',startaddr=0)
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
        (fuid,returned_datalist)=chip.mbus.send_memory_read(2,0x3C1C/4,23,1,0)
else:
    chip = libra.libra(0)

total_time = time.time()-start
print 'total time %s' %(total_time)

(fuid,returned_datalist)=chip.mbus.send_memory_read(2,0x3C00/4,256,1,0)
returned_datalist = list(itertools.chain(*returned_datalist))
returned_datalist = [int(s,2) for s in returned_datalist]
word_error_cnt = returned_datalist[1]
single_word_cnt = returned_datalist[2]
multi_word_cnt = returned_datalist[3]
bit_error_cnt = returned_datalist[4]
single_bit_cnt = returned_datalist[5]
multi_bit_cnt = returned_datalist[6]
total_word_tested = returned_datalist[7]

error_summary = 9
error_summary_multi = error_summary+11
error_detail = 31

single_word_bank = []
multi_word_bank = []
single_dict = {}
single_bank_dict = {}
multi_dict = {}
multi_bank_dict = {}

for i in range(223):
    single_word_bank.append(returned_datalist[error_detail+i] >> 16);
    multi_word_bank.append(returned_datalist[error_detail+i] & 0x0000FFFF);
    
    (block_name,block_num) = block_map(i)

    ne_shared_mem_test_list = [0,1,2,3,4,5,6,7,8,10,12,16,18,20,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,48,49,50,51]

    if block_name not in multi_dict:
        multi_dict[block_name] = []
    if block_name not in single_dict:
        single_dict[block_name] = []

    if single_word_bank[i] != 0:
        single_dict[block_name].append('{}({})'.format(block_num,single_word_bank[i]))
    if multi_word_bank[i] != 0:
        multi_dict[block_name].append('{}({})'.format(block_num,multi_word_bank[i]))

    if single_word_bank[i] != 0 or multi_word_bank[i] != 0:
        if ('IMG_CD' in multi_dict and multi_dict['IMG_CD'] ) or ('IMG_REF' in multi_dict and multi_dict['IMG_REF']): 
            IMG_Usable = False
        if ('IMG_COMP' in multi_dict and multi_dict['IMG_COMP']) or ('IMG_COMP' in single_dict and single_dict['IMG_COMP']):
            if block_name == 'IMG_COMP' and ( 0 <= block_num <=16 or 35<= block_num <= 45 ):
                IMG_Usable = False
        #if ('NE_Weight' in multi_dict and multi_dict['NE_Weight']) or ('NE_Local' in multi_dict and multi_dict['NE_Local']) or ('NE_Accum' in multi_dict and multi_dict['NE_Accum']) or ('NE_Bias' in multi_dict and multi_dict['NE_Bias']): 
        #    NE_Usable = False
        #if ('NE_Instr' in multi_dict and multi_dict['NE_Instr' ]) or ('NE_Instr' in single_dict and single_dict['NE_Instr']):
        #    NE_Usable = False
        #if ('NE_Shared' in multi_dict and multi_dict['NE_Shared']) or ('NE_Shared' in single_dict and single_dict['NE_Shared']):
        #    if block_name == 'NE_Shared' and ( block_num in ne_shared_mem_test_list ):
        #        NE_Usable = False
        #if ('H264' in multi_dict and multi_dict['H264']) or ('H264' in single_dict and single_dict['H264']):
        #    H264_Usable = False

        if ('IMG_CD' in single_dict and single_dict['IMG_CD']):
            IMG_Quality = False
        if ('IMG_REF' in single_dict and single_dict['IMG_REF']):
            IMG_Quality = False
        if ('NE_Weight' in single_dict and single_dict['NE_Weight']):
            NE_Quality = False
        if ('NE_Local' in single_dict and single_dict['NE_Local']):
            NE_Quality = False
        if ('NE_Accum' in single_dict and single_dict['NE_Accum']):
            NE_Quality = False
        if ('NE_Bias' in single_dict and single_dict['NE_Bias']):
            NE_Quality = False

test_log = 'Subject: MEM Test finished\n'
test_log += 'total time %s second\n' %total_time
if run_mainMem_test:
    test_log += 'MainMem has %s error words\n' %mainMem_error
    test_log += 'MainMem error banks are {}\n'.format(main_errorbank)
    test_log += 'total_word_tested:\t %s \n' %(total_word_tested + 16384)
else:
    test_log += 'MainMem test skipped\n'
    test_log += 'total_word_tested:\t %s \n' %(total_word_tested)
test_log += 'word_error_cnt   :\t %s \n' %word_error_cnt
test_log += 'single_word_cnt  :\t %s \n' %single_word_cnt
test_log += 'multi_word_cnt   :\t %s \n' %multi_word_cnt
test_log += 'bit_error_cnt    :\t %s \n' %bit_error_cnt
test_log += 'single_bit_cnt   :\t %s \n' %single_bit_cnt
test_log += 'multi_bit_cnt    :\t %s \n' %multi_bit_cnt
test_log += '1. MINMAX MEM (1)       \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary] & 0x0FFFFFFF, single_dict['IMG_MinMax'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['IMG_MinMax']), multi_dict['IMG_MinMax'])
test_log += '2. CD MEM (8)         \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+1] & 0x0FFFFFFF, single_dict['IMG_CD'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['IMG_CD']), multi_dict['IMG_CD'])
test_log += '3. REF MEM (3)        \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+2] & 0x0FFFFFFF, single_dict['IMG_REF'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['IMG_REF']), multi_dict['IMG_REF'])
test_log += '4. COMP MEM (55)      \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+3] & 0x0FFFFFFF, single_dict['IMG_COMP'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['IMG_COMP']), multi_dict['IMG_COMP'])
test_log += '5. NE shared MEM (80) \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+4] & 0x0FFFFFFF, single_dict['NE_Shared'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['NE_Shared']), multi_dict['NE_Shared'])
test_log += '6. NE weight MEM (4)  \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+5] & 0x0FFFFFFF, single_dict['NE_Weight'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['NE_Weight']), multi_dict['NE_Weight'])
test_log += '7. NE Instr MEM (2)   \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+6] & 0x0FFFFFFF, single_dict['NE_Instr'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['NE_Instr']), multi_dict['NE_Instr'])
test_log += '8. NE local MEM (4)   \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+7] & 0x0FFFFFFF, single_dict['NE_Local'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['NE_Local']), multi_dict['NE_Local'])
test_log += '9. NE accum MEM (64)  \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+8] & 0x0FFFFFFF, single_dict['NE_Accum'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['NE_Accum']), multi_dict['NE_Accum'])
test_log += '10. NE Bias MEM (1)   \t   \t\n' 
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+9] & 0x0FFFFFFF, single_dict['NE_Bias'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n'.format(len(multi_dict['NE_Bias']), multi_dict['NE_Bias'])
test_log += '11. H264 MEM (1)      \t   \t\n'
test_log += '\tsingle word  :\t {} \t\t{} \n'.format(returned_datalist[error_summary+10] & 0x0FFFFFFF, single_dict['H264'])
test_log += '\tmulti  bank# :\t {} \t\t{} \n\n'.format(len(multi_dict['H264']), multi_dict['H264'])

###NE shared mem###
ne_shared_map = np.zeros((20,4))
for single_bank in single_dict['NE_Shared']:
	bank=int(single_bank.split('(')[0])
	err=int(single_bank.split('(')[1][:-1])
	ne_shared_map[bank/4][bank%4] = err
for multi_bank in multi_dict['NE_Shared']:
	bank=int(multi_bank.split('(')[0])
	err=int(multi_bank.split('(')[1][:-1])
	ne_shared_map[bank/4][bank%4] = err

x_label = ['0','1','2','3']
y_label = []
for i in range(20):
	addr=0xA0104100+i*(128*512)/8*4
	addr_32bit=(addr-0xA0104100)/4
	addr_128bit=(addr_32bit)/4
	addr_256bit=(addr_128bit)/4
	y_label.append(str(hex(addr))[:-1] +' ('+str(addr_32bit)+':'+str(addr_128bit)+':'+str(addr_256bit)+')')

fig, ax = plt.subplots()
im, cbar = heatmap(ne_shared_map, y_label, x_label, ax=ax, cmap="Reds", cbarlabel="error [words/bank]")
texts = annotate_heatmap(im, valfmt="{x:.0f}")
fig.tight_layout()
plt.show()


if not IMG_Usable:
    test_log += 'IMG not Usable\n'
elif not IMG_Quality:
    test_log += 'IMG quality degraded\n'
else:
    test_log += 'IMG very Good!\n'

#if not NE_Usable:
#    test_log += 'NE not Usable\n'
if not NE_Quality:
    test_log += 'NE quality degraded\n'
else:
    test_log += 'NE very Good!\n'

if not H264_Usable:
    test_log += 'H264 not Usable\n'
else:
    test_log += 'H264 very Good!\n'
    
test_log += '\n'

if allow_email_alert:
    send_email(from_usr, password, to_usr, test_log)

if total_word_tested != 262144:
    exit()

ne_shared_errmap = []
for item in range(20):
    ne_shared_errmap.append([[],[],[],[]])
if single_word_cnt > 0:
    (fuid,addrlist)=chip.mbus.send_memory_read(2,0x4000/4,sum(single_word_bank),1,0)
    addrlist = list(itertools.chain(*addrlist))
    addrlist = [int(s,2) for s in addrlist]
    
    (fuid,error_data_list)=chip.mbus.send_memory_read(2,0x8000/4,sum(single_word_bank),1,0)
    error_data_list = list(itertools.chain(*error_data_list))
    error_data_list = [int(s,2) for s in error_data_list]
    
    (fuid,xorlist)=chip.mbus.send_memory_read(2,0xC000/4,sum(single_word_bank),1,0)
    xorlist = list(itertools.chain(*xorlist))
    xorlist = [int(s,2) for s in xorlist]

    test_log += "Detailed Log for single bit errors\n"
    test_log += "{}\t{}\t{}\n".format('error_addr','error_data','xor_result')
    cnt = 1
    ne_shared_row = 0
    ne_shared_col = 0
    for i in range(223):
        (block_name,block_num) = block_map(i)
        bank_offset = 0
        if single_word_bank[i] != 0:
	    if block_name is 'NE_Shared' :
               bank_offset = int('0xA0104100',16)+int(block_num)*(2048*4)
            test_log += "===================== {} MEM Bank {}: {} words fail =========================: \n".format(block_name, block_num, single_word_bank[i])
            for j in range(single_word_bank[i]):
		if block_name is 'NE_Shared':
                	test_log += "{}\t{}\t{}\n".format('0d'+str((addrlist[cnt]-bank_offset)/4),'0d'+str((addrlist[cnt]-bank_offset)/16),'0d'+str((addrlist[cnt]-bank_offset)/64),'0x'+hex(error_data_list[cnt]).rstrip('L')[2:].zfill(8),bin(xorlist[cnt])[2:].zfill(32))
			ne_shared_errmap[ne_shared_row][ne_shared_col].append(str((addrlist[cnt]-bank_offset)/4))
		else:
                	test_log += "{}\t{}\t{}\n".format('0x'+hex(addrlist[cnt]-bank_offset).rstrip('L')[2:].zfill(8),'0x'+hex(error_data_list[cnt]).rstrip('L')[2:].zfill(8),bin(xorlist[cnt])[2:].zfill(32))
                cnt+=1
	if block_name is 'NE_Shared' :
           if ne_shared_col == 3:
              ne_shared_col = 0
              ne_shared_row = ne_shared_row + 1
           else :
              ne_shared_col = ne_shared_col + 1

filename = "./05_memorytest/{}_detail_{}_{}_{}.log".format(chipID, VDD_core, VDD_mem, Date)
ofile_memread= open(filename,'w')
ofile_memread.write(test_log)
ofile_memread.close()

print DataFrame(ne_shared_errmap)
#chip.read_prog_mem(filename='ISP07_all_0p6_0p353.log',startaddr=0x3C00/4,length=30)
