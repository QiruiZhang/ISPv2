#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# NeuralEngine Assembler 2: The Sequel #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


import sys
import re
import argparse
from pprint import pprint as pprint
parser = argparse.ArgumentParser()
parser.add_argument("input", help="input .asm file")
args = parser.parse_args()


##########################################################################################


################################
# binary/hex related functions #
################################


def bindigits(n, bits):
    s = bin(int(n) & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % bits).format(s)


def bininst(opcode, include_bias, max_0_avg_1, process_kernel_size, output_kernel_size, stride, ic_size, start_ic, current_ic, finish_ic, oc_size, start_oc, current_oc, finish_oc, \
            ia_size, ia_row_start, ia_col_start, ia_row_end, ia_col_end, ia_row_size, ia_col_size, oa_size, shift_width, \
            ia_mem_addr_0, ia_mem_dir_0, ia_mem_buffer_0, ia_mem_addr_1, ia_mem_dir_1, ia_mem_buffer_1, oa_mem_addr, oa_mem_dir, oa_mem_buffer, \
            resize_factor, cwram_addr, conv_clear_finished, conv_clear_addr):
    return bindigits(opcode, 4) + bindigits(include_bias, 1) + bindigits(max_0_avg_1, 1) + bindigits(process_kernel_size, 4) + bindigits(output_kernel_size, 4) + \
           bindigits(stride, 4) + bindigits(ic_size, 12) + bindigits(start_ic, 12) + bindigits(current_ic, 12) + bindigits(finish_ic, 12) + bindigits(oc_size, 12) + bindigits(start_oc, 12) + \
           bindigits(current_oc, 12) + bindigits(finish_oc, 12) + bindigits(ia_size, 5) + bindigits(ia_row_start, 5) + bindigits(ia_col_start, 5) + \
           bindigits(ia_row_end, 5) + bindigits(ia_col_end, 5) + bindigits(ia_row_size, 8) + bindigits(ia_col_size, 8) + bindigits(oa_size, 8) + bindigits(shift_width, 5) + \
           bindigits(ia_mem_addr_0, 5) + bindigits(ia_mem_dir_0, 1) + bindigits(ia_mem_buffer_0, 1) + bindigits(ia_mem_addr_1, 5) + bindigits(ia_mem_dir_1, 1) + bindigits(ia_mem_buffer_1, 1) + \
           bindigits(oa_mem_addr, 5) + bindigits(oa_mem_dir, 1) + bindigits(oa_mem_buffer, 1) + \
           bindigits(resize_factor, 8) + bindigits(cwram_addr, 5) + bindigits(conv_clear_finished, 1) + bindigits(conv_clear_addr, 10) + bindigits(0,43)


def pe_inst_from_params(opcode,parameters):
    return bininst(opcode, \
            int(parameters['include_bias']), \
            int(parameters['max_0_avg_1']), \
            int(parameters['process_kernel_size']), \
            int(parameters['output_kernel_size']), \
            int(parameters['stride']), \
            int(parameters['ic_size']), \
            int(parameters['start_ic']), \
            int(parameters['current_ic']), \
            int(parameters['finish_ic']), \
            int(parameters['oc_size']), \
            int(parameters['start_oc']), \
            int(parameters['current_oc']), \
            int(parameters['finish_oc']), \
            int(parameters['ia_size']), \
            int(parameters['ia_row_start']), \
            int(parameters['ia_col_start']), \
            int(parameters['ia_row_end']), \
            int(parameters['ia_col_end']), \
            int(parameters['ia_row_size']), \
            int(parameters['ia_col_size']), \
            int(parameters['oa_size']), \
            int(parameters['shift_width']), \
            int(parameters['ia_mem_addr_0']), \
            int(parameters['ia_mem_dir_0']), \
            int(parameters['ia_mem_buffer_0']), \
            int(parameters['ia_mem_addr_1']), \
            int(parameters['ia_mem_dir_1']), \
            int(parameters['ia_mem_buffer_1']), \
            int(parameters['oa_mem_addr']), \
            int(parameters['oa_mem_dir']), \
            int(parameters['oa_mem_buffer']), \
            int(parameters['resize_factor']), \
            int(parameters['cwram_addr']), \
            int(parameters['conv_clear_finished']), \
            int(parameters['conv_clear_addr']))


def hexify(binstring, uselongword):
    hstr = '%0*X' % ((len(binstring) + 3) // 4, int(binstring, 2))
    if(uselongword):
        return hstr
    else:
        return hstr[::-1]

##########################################################################################

###############################
# PE op param 'relevant name' #
# to 'hw name' translator     #
###############################

def rel2hw(op,p):
    if(p == "skip_localmem_clear"):
        return "conv_clear_finished"
    elif(p == "localmem_clear_addr"):
        return "conv_clear_addr"

    if(op == "MOV"):
        if(p == "top_pad_rows"):
            return "process_kernel_size"
        elif(p == "left_pad_cols"):
            return "output_kernel_size"
        else:
            return p
    elif(op == "HUFF"):
        if(p == "w_0_loc_1"):
            return "max_0_avg_1"
        elif(p == "table_start_addr"):
            return "ia_mem_addr_0"
        elif(p == "table_end_addr"):
            return "ia_mem_addr_1"
        elif(p == "last_word_valid_mask"):
            return "resize_factor"
        else:
            return p
    elif(op == "BIAS"):
        if(p == "start_addr"):
            return "ia_mem_addr_0"
        elif(p == "end_addr"):
            return "ia_mem_addr_1"
        else:
            return p
    elif(op == "DFC"):
        if(p == "keep_existing_oa_data"):
            return "max_0_avg_1"
        elif(p == "bias_index"):
            return "ia_mem_addr_1"
        elif(p == "insert_row"):
            return "oa_mem_addr"
        elif(p == "insert_col"):
            return "ia_col_start"
        elif(p == "insert_chan"):
            return "ia_row_start"
        else:
            return p
    else:
        return p


###############################
# PE op param 'hw name' to    #
# 'relevant name' translator  #
###############################

def hw2rel(op,p):
    if(p == "conv_clear_finished"):
        return "skip_localmem_clear"
    elif(p == "conv_clear_addr"):
        return "localmem_clear_addr"

    if(op == "MOV"):
        if(p == "process_kernel_size"):
            return "top_pad_rows"
        elif(p == "output_kernel_size"):
            return "left_pad_cols"
        else:
            return p
    elif(op == "HUFF"):
        if(p == "max_0_avg_1"):
            return "w_0_loc_1"
        elif(p == "ia_mem_addr_0"):
            return "table_start_addr"
        elif(p == "ia_mem_addr_1"):
            return "table_end_addr"
        elif(p == "resize_factor"):
            return "last_word_valid_mask"
        else:
            return p
    elif(op == "BIAS"):
        if(p == "ia_mem_addr_0"):
            return "start_addr"
        elif(p == "ia_mem_addr_1"):
            return "end_addr"
        else:
            return p
    elif(op == "DFC"):
        if(p == "max_0_avg_1"):
            return "keep_existing_oa_data"
        elif(p == "ia_mem_addr_1"):
            return "bias_index"
        elif(p == "oa_mem_addr"):
            return "insert_row"
        elif(p == "ia_col_start"):
            return "insert_col"
        elif(p == "ia_row_start"):
            return "insert_chan"
        else:
            return p
    else:
        return p





##########################################################################################

###########################
# PE op parameter checker #
###########################

def validate_pe_params(op,p,l):

    # things will be defined as '0' (CHARACTER, NOT NUMBER)
    # if they have not been specified by the programmer
    if(op == "CONV"):
        reqs = ['process_kernel_size','output_kernel_size','stride','shift_width','include_bias',\
                'ic_size','start_ic','current_ic','finish_ic','oc_size','start_oc','current_oc',\
                'finish_oc','ia_size','oa_size','ia_mem_buffer_0','oa_mem_buffer','cwram_addr']
        if(p['ic_size'] < 8):
            print("WARN, line %d: unsupported number of input channels: %d" % (l,p['ic_size']))
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        if(p['output_kernel_size'] != 1):
            print("WARN, line %d: invalid CONV output kernel size %d. Please use 1." % (l,p['output_kernel_size']))
        if(p['stride'] != 1 and p['stride'] != 2 and p['stride'] != 4 and p['stride'] != 8):
            print("WARN, line %d: invalid CONV stride %d. Please use 1,2,4,8" % (l,p['stride']))
        if(p['process_kernel_size'] > 7):
            print("WARN, line %d: CONV filter size >7x7 is not well-tested" % (l,p['process_kernel_size']))
        if(p['process_kernel_size'] <= 0):
            print("WARN, line %d: CONV filter size of %dx%d? Are you sure??" % (l,p['process_kernel_size'],p['process_kernel_size']))
        if(p['shift_width'] >= 32):
            print("WARN, line %d: shift_width of %d would make eveything zero!" % (l,p['shift_width']))
        if(p['oa_size'] > 16):
            print("WARN, line %d: invalid oa_size %d" % (l,p['oa_size']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "POOL"):
        reqs = ['process_kernel_size','output_kernel_size','stride','shift_width','max_0_avg_1',\
                'ic_size','start_ic','current_ic','finish_ic','oc_size','start_oc','current_oc',\
                'finish_oc','ia_size','oa_size','ia_mem_buffer_0','oa_mem_buffer']
        if(p['ic_size'] < 8):
            print("WARN, line %d: unsupported number of input channels: %d" % (l,p['ic_size']))
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        if(p['output_kernel_size'] != 1):
            print("WARN, line %d: invalid POOL output kernel size %d. Please use 1." % (l,p['output_kernel_size']))
        if(p['stride'] != 1 and p['stride'] != 2 and p['stride'] != 4 and p['stride'] != 8):
            print("WARN, line %d: invalid POOL stride %d. Please use 1,2,4,8" % (l,p['stride']))
        if(p['process_kernel_size'] > 7):
            print("WARN, line %d: POOL filter size >7x7 is not well-tested" % (l,p['process_kernel_size']))
        if(p['process_kernel_size'] <= 0):
            print("WARN, line %d: POOL filter size of %dx%d? Are you sure??" % (l,p['process_kernel_size'],p['process_kernel_size']))
        if(p['shift_width'] >= 32):
            print("WARN, line %d: shift_width of %d would make eveything zero!" % (l,p['shift_width']))
        if(p['oa_size'] > 16):
            print("WARN, line %d: invalid oa_size %d" % (l,p['oa_size']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "MOV"):
        reqs = ['ic_size','start_ic','current_ic','finish_ic','ia_size','oa_size','ia_mem_dir_0',\
                'oa_mem_dir','ia_row_start','ia_col_start','ia_row_end','ia_col_end',\
                'oa_mem_addr']
        if(p['ia_mem_dir_0'] == 0 and p['ia_mem_buffer_0'] == '0'):
            sys.exit("ERROR, line %d: need to specify ia_mem_buffer_0 for PE opcode MOV" % l)
        if(p['oa_mem_dir'] == 0 and p['oa_mem_buffer'] == '0'):
            sys.exit("ERROR, line %d: need to specify oa_mem_buffer for PE opcode MOV" % l)
        if(p['ia_mem_dir_0'] == 1 and p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: cannot MOV data from sharedmem to sharedmem!" % l)
        if(p['ic_size'] > 1 and p['ic_size'] < 8):
            print("WARN, line %d: unsupported number of input channels: %d" % (l,p['ic_size']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "ADD"):
        reqs = ['ia_mem_buffer_0','ia_mem_buffer_1','ia_size','ic_size','shift_width','oa_mem_buffer']
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        if(p['shift_width'] >= 32):
            print("WARN, line %d: shift_width of %d would make eveything zero!" % (l,p['shift_width']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "FC"):
        reqs = ['oc_size','ic_size','ia_mem_buffer_0','ia_size','include_bias','shift_width',\
                'oa_mem_buffer','cwram_addr']
        if(p['ic_size'] < 8):
            print("WARN, line %d: unsupported number of input channels: %d" % (l,p['ic_size']))
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        if(p['shift_width'] >= 32):
            print("WARN, line %d: shift_width of %d would make eveything zero!" % (l,p['shift_width']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "RELU"):
        reqs = ['ia_mem_buffer_0','ia_size','ic_size','oa_size','oa_mem_buffer']
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "HUFF"):
        reqs = ['max_0_avg_1','ia_mem_addr_0','ia_mem_addr_1','resize_factor']
        if(p['resize_factor'] == 0):
            print("WARN, line %d: you really shouldn't set last_word_valid_mask=0. Did you mean =255?" % l)
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "BIAS"):
        reqs = ['ia_mem_addr_0','ia_mem_addr_1']
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "RESIZE"):
        reqs = ['process_kernel_size','output_kernel_size','stride','shift_width','include_bias',\
                'ic_size','start_ic','current_ic','finish_ic','oc_size','start_oc','current_oc',\
                'finish_oc','ia_size','oa_size','ia_mem_buffer_0','oa_mem_buffer','resize_factor']
        if(p['ic_size'] < 8):
            print("WARN, line %d: unsupported number of input channels: %d" % (l,p['ic_size']))
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        if(p['output_kernel_size'] != 1):
            print("WARN, line %d: invalid CONV/RESIZE output kernel size %d. Please use 1." % (l,p['output_kernel_size']))
        if(p['stride'] != 1 and p['stride'] != 2 and p['stride'] != 4 and p['stride'] != 8):
            print("WARN, line %d: invalid CONV/RESIZE stride %d. Please use 1,2,4,8" % (l,p['stride']))
        if(p['process_kernel_size'] > 7):
            print("WARN, line %d: CONV/RESIZE filter size >7x7 is not well-tested" % (l,p['process_kernel_size']))
        if(p['process_kernel_size'] <= 0):
            print("WARN, line %d: CONV/RESIZE filter size of %dx%d? Are you sure??" % (l,p['process_kernel_size'],p['process_kernel_size']))
        if(p['shift_width'] >= 32):
            print("WARN, line %d: shift_width of %d would make eveything zero!" % (l,p['shift_width']))
        if(p['oa_size'] > 16):
            print("WARN, line %d: invalid oa_size %d" % (l,p['oa_size']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))
    elif(op == "DFC"):
        reqs = ['oc_size','oa_size','ic_size','current_ic','include_bias','shift_width',\
                'cwram_addr','ia_row_start','ia_col_start','ia_mem_addr_1','oa_mem_addr',\
                'ia_mem_buffer_0', 'oa_mem_buffer']
        if(p['ic_size'] < 8):
            print("WARN, line %d: unsupported number of input channels: %d" % (l,p['ic_size']))
        if(p['ia_mem_dir_0'] == 1):
            sys.exit("ERROR, line %d: %s cannot get ia directly from sharedmem" % (l,op))
        if(p['oa_mem_dir'] == 1):
            sys.exit("ERROR, line %d: %s cannot write oa directly to sharedmem" % (l,op))
        if(p['max_0_avg_1'] == 1 and p['conv_clear_finished'] != 1):
            print("WARN, line %d: you should change skip_localmem_clear to 1 since you set keep_existing_oa_data=1" % l)
        if(p['shift_width'] >= 32):
            print("WARN, line %d: shift_width of %d would make eveything zero!" % (l,p['shift_width']))
        if(p['oc_size'] != 1):
            print("WARN, line %d: invalid oc_size %d for DFC. Please use 1." % (l,p['oc_size']))
        if(p['oa_size'] != 1):
            print("WARN, line %d: invalid oa_size %d for DFC. Please use 1." % (l,p['oc_size']))
        for r in reqs:
            if(p[r] == '0'):
                sys.exit("ERROR, line %d: need to specify %s for PE opcode %s" % (l,hw2rel(op,r),op))





##########################################################################################


###############################
# encoder for PE instructions #
###############################


def encode_pe_inst(inst,linenum):
    parameters = {}
    parameters['process_kernel_size'] = '0'
    parameters['output_kernel_size'] = '0'
    parameters['stride'] = '0'
    parameters['max_0_avg_1'] = '0'
    parameters['shift_width'] = '0'
    parameters['resize_factor'] = '0'
    parameters['include_bias'] = '0'
    parameters['ic_size'] = '0'
    parameters['start_ic'] = '0'
    parameters['current_ic'] = '0'
    parameters['finish_ic'] = '0'
    parameters['oc_size'] = '0'
    parameters['start_oc'] = '0'
    parameters['current_oc'] = '0'
    parameters['finish_oc'] = '0'
    parameters['ia_size'] = '0'
    parameters['oa_size'] = '0'
    parameters['ia_mem_addr_0'] = '0'
    parameters['ia_mem_addr_1'] = '0'
    parameters['ia_mem_dir_0'] = '0'
    parameters['ia_mem_dir_1'] = '0'
    parameters['ia_mem_buffer_0'] = '0'
    parameters['ia_mem_buffer_1'] = '0'
    parameters['oa_mem_addr'] = '0'
    parameters['oa_mem_dir'] = '0'
    parameters['oa_mem_buffer'] = '0'
    parameters['cwram_addr'] = '0'
    parameters['ia_row_size'] = '0'
    parameters['ia_col_size'] = '0'
    parameters['ia_row_start'] = '0'
    parameters['ia_col_start'] = '0'
    parameters['ia_row_end'] = '0'
    parameters['ia_col_end'] = '0'
    parameters['conv_clear_finished'] = '0'
    parameters['conv_clear_addr'] = '0'

    params_w_regs = ['ia_size', 'ia_row_start', 'ia_col_start', 'ia_row_end',\
                     'ia_col_end', 'ia_mem_addr_0', 'ia_mem_addr_1',\
                     'oa_mem_addr', 'cwram_addr']

    # trim out any blanks
    inst = [x for x in inst if x]

    if inst[0] == "CONV":
        opcode = 0
        parameters['output_kernel_size'] = 1
    elif inst[0] == "POOL":
        opcode = 1
        parameters['output_kernel_size'] = 1
    elif inst[0] == "MOV":
        opcode = 2
    elif inst[0] == "ADD":
        opcode = 3
    elif inst[0] == "FC":
        opcode = 4
        parameters['output_kernel_size'] = 1
    elif inst[0] == "RELU":
        opcode = 5
        parameters['output_kernel_size'] = 0
    elif inst[0] == "HUFF":
        opcode = 6
        parameters['resize_factor'] = 255
    elif inst[0] == "BIAS":
        opcode = 7
    elif inst[0] == "RESIZE":
        opcode = 8
        parameters['output_kernel_size'] = 1
    elif inst[0] == "DFC":
        opcode = 10
        parameters['oc_size'] = 1
        parameters['oa_size'] = 1
    else:
        sys.exit("ERROR, line %d: unknown PE opcode %s" % (linenum,inst[0]))

    operand = ""
    waiting = 0 # 0=none, 1=need'=', 2=needvalue
    for item in inst[1:]:

        if(waiting == 1):
            if(item == '='):
                waiting = 2
            else:
                sys.exit("ERROR, line %d: something was added before the = sign for opcode %s" % (linenum,inst[0]))
        elif(waiting == 2):
            if(parameters[rel2hw(inst[0],operand)]):
                dirflag = False
                if(operand == "ia_mem_dir_0" or operand == "ia_mem_dir_1" or operand == "oa_mem_dir"):
                    if(item == 'shared'):
                        parameters[rel2hw(inst[0],operand)] = int(1)
                        dirflag = True
                    elif(item == 'local'):
                        parameters[rel2hw(inst[0],operand)] = int(0)
                        dirflag = True

                if(dirflag == False):
                    if(item[0] == 'r'):
                        if rel2hw(inst[0],operand) in params_w_regs:
                            if(int(item[1:]) < 24 and int(item[1:]) >= 0):
                                parameters[rel2hw(inst[0],operand)] = int(item[1:])
                            else:
                                sys.exit("ERROR, line %d: invalid register %s" % (linenum,item))
                        else:
                            sys.exit("ERROR, line %d: %s uses constants, not registers" % (linenum,operand))
                    else:
                        if rel2hw(inst[0],operand) in params_w_regs:
                            sys.exit("ERROR, line %d: %s uses registers, not constants" % (linenum,operand))
                        else:
                            parameters[rel2hw(inst[0],operand)] = int(item)
                waiting = 0
            else:
                sys.exit("ERROR, line %d: unknown option %s given for opcode %s" % (linenum, operand, inst[0]))
        elif(waiting == 0):
            operand = item
            waiting = 1

    #print("\n%s" % inst[0])
    #pprint(parameters)
    validate_pe_params(inst[0],parameters,linenum)
    return pe_inst_from_params(opcode,parameters)



##########################################################################################

#######################
# Encoder for NCX ops #
#######################


def encode_ncx_inst(inst,linenum):
    ncxdict = {}

    #------------------------
    # argument types are:
    #  0: none
    #  1: register
    # 20: 16-bit immediate
    # 21: 8-bit immediate in 16 bits
    # 22: 4-bit immediate in 16 bits
    #  3: 9-bit CISC addr
    #  4: 3-bit RISC addr
    #  5: special
    #
    #                       opcode  arg1 arg2 arg3 arg4
    ncxdict['ncx_NOOP']  = ["00000"]
    ncxdict['ncx_ADD']   = ["00001",  1,   1,   1]
    ncxdict['ncx_ADDI']  = ["00010",  1,   1,"20"]
    ncxdict['ncx_SUB']   = ["00011",  1,   1,   1]
    ncxdict['ncx_SUBI']  = ["00100",  1,   1,"20"]
    ncxdict['ncx_MOV']   = ["00101",  1,   1]
    ncxdict['ncx_MOVI']  = ["00110",  1,"20"]
    ncxdict['ncx_LDS']   = ["00111",  1,   1,   1]
    ncxdict['ncx_STS']   = ["01000",  1,   1,   1]
    ncxdict['ncx_BEQ']   = ["01001",  1,   1,   3,   4]
    ncxdict['ncx_BNE']   = ["01010",  1,   1,   3,   4]
    ncxdict['ncx_BLT']   = ["01011",  1,   1,   3,   4]
    ncxdict['ncx_BGT']   = ["01100",  1,   1,   3,   4]
    ncxdict['ncx_BLE']   = ["01101",  1,   1,   3,   4]
    ncxdict['ncx_BGE']   = ["01110",  1,   1,   3,   4]
    ncxdict['ncx_CP_B']  = ["01111",  1,   1,   1,   5]
    ncxdict['ncx_CP_W']  = ["10000",  1,   1]
    ncxdict['ncx_MULT']  = ["10001",  1,   1,   1]
    ncxdict['ncx_MULTI'] = ["10010",  1,   1,"21"]
    ncxdict['ncx_MULTS'] = ["10011",  1,   1,   1]
    ncxdict['ncx_AND']   = ["10100",  1,   1,   1]
    ncxdict['ncx_OR']    = ["10101",  1,   1,   1]
    ncxdict['ncx_XOR']   = ["10110",  1,   1,   1]
    ncxdict['ncx_NAND']  = ["10111",  1,   1,   1]
    ncxdict['ncx_LSR']   = ["11000",  1,   1,"22"]
    ncxdict['ncx_LSL']   = ["11001",  1,   1,"22"]
    ncxdict['ncx_HALT']  = ["11111"]


    if(not ncxdict[inst[0]]):
        sys.exit("ERROR, line %d: unknown instruction %s" % (linenum,inst[0]))

    result = ncxdict[inst[0]][0]
    argvect = inst[1:]

    # trim any whitespaces
    inst = [x for x in inst if x]

    nex = []
    for x in inst:
        if(x.split(',')):
            nex.append(x.split(',')[0])
    inst = nex

    if(inst[0] != 'ncx_CP_B'):
        if( len(inst) != len(ncxdict[inst[0]]) ):
            sys.exit("ERROR, line %d: %s needs %d arguments, found %d" % (linenum,inst[0],len(ncxdict[inst[0]])-1,len(inst)-1))
        else:
            # 3-argument instructions
            if(len(ncxdict[inst[0]]) == 4):

                # 3-register instructions
                if(ncxdict[inst[0]][1] == 1 and ncxdict[inst[0]][2] == 1 and ncxdict[inst[0]][3] == 1):
                    if(inst[1][0] == 'r'):
                        nummed = int(inst[1][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[1][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))
                    if(inst[2][0] == 'r'):
                        nummed = int(inst[2][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[2][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[2]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 2 must be a register" % (linenum,inst[0]))
                    if(inst[3][0] == 'r'):
                        nummed = int(inst[3][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[3][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[3]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 3 must be a register" % (linenum,inst[0]))

                    result += "0"*11 # unused bits

                # 2-register and 1-immediate instructions
                elif(ncxdict[inst[0]][1] == 1 and ncxdict[inst[0]][2] == 1 and ncxdict[inst[0]][3][0] == "2"):
                    if(inst[1][0] == 'r'):
                        nummed = int(inst[1][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[1][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))
                    if(inst[2][0] == 'r'):
                        nummed = int(inst[2][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[2][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[2]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 2 must be a register" % (linenum,inst[0]))
                    if(inst[3][0] == '#'):
                        nummed = int(inst[3][1:])
                        # bounds checks for 16, 8, or 4 bits
                        if(ncxdict[inst[0]][3] == "20"):
                            # 16 bit
                            if(nummed >= 0 and nummed < 65536):
                                result += bindigits(int(inst[3][1:]),16)
                            else:
                                sys.exit("ERROR, line %d: immediate %s does not fit in unsigned 16-bit" % (linenum,inst[3][1:]))
                        elif(ncxdict[inst[0]][3] == "21"):
                            # 8 bit
                            if(nummed >= 0 and nummed < 256):
                                result += bindigits(int(inst[3][1:]),16)
                            else:
                                sys.exit("ERROR, line %d: immediate %s does not fit in unsigned 8-bit" % (linenum,inst[3][1:]))
                        elif(ncxdict[inst[0]][3] == "22"):
                            # 4 bit
                            if(nummed >= 0 and nummed < 16):
                                result += bindigits(int(inst[3][1:]),16)
                            else:
                                sys.exit("ERROR, line %d: immediate %s does not fit in unsigned 4-bit" % (linenum,inst[3][1:]))
                        else:
                            sys.exit("BUG: malformed NCX instruction table while processing line %d" % linenum)

                else:
                    sys.exit("BUG: malformed NCX instruction table while processing line %d" % linenum)


            # 2-argument instructions
            elif(len(ncxdict[inst[0]]) == 3):

                # 2-register
                if(ncxdict[inst[0]][1] == 1 and ncxdict[inst[0]][2] == 1):
                    if(inst[1][0] == 'r'):
                        nummed = int(inst[1][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[1][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))
                    if(inst[2][0] == 'r'):
                        nummed = int(inst[2][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[2][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[2]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 2 must be a register" % (linenum,inst[0]))

                    result += "0"*16 # unused bits

                # 1-reg and 1-imm (aka, MOVI)
                elif(ncxdict[inst[0]][1] == 1 and ncxdict[inst[0]][2] == "20"):
                    if(inst[1][0] == 'r'):
                        nummed = int(inst[1][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[1][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))

                    result += "0"*5 # reg gap

                    if(inst[2][0] == '#'):
                        nummed = int(inst[2][1:])
                        # bounds checks for 16, 8, or 4 bits
                        if(ncxdict[inst[0]][2] == "20"):
                            # 16 bit
                            if(nummed >= 0 and nummed < 65536):
                                result += bindigits(int(inst[2][1:]),16)
                            else:
                                sys.exit("ERROR, line %d: immediate %s does not fit in unsigned 16-bit" % (linenum,inst[3][1:]))

                else:
                    sys.exit("BUG: malformed NCX instruction table while processing line %d" % linenum)

            # 0-argument instructions
            elif(len(ncxdict[inst[0]]) == 1):
                result += "0"*26

            # 4-argument branch instructions
            elif(len(ncxdict[inst[0]]) == 5):

                # extra check for 4-argument branch
                if(ncxdict[inst[0]][1] == 1 and ncxdict[inst[0]][2] == 1 and ncxdict[inst[0]][3] == 3 and ncxdict[inst[0]][4] == 4):
                    if(inst[1][0] == 'r'):
                        nummed = int(inst[1][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[1][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))
                    if(inst[2][0] == 'r'):
                        nummed = int(inst[2][1:])
                        if(nummed >= 0 and nummed < 24):
                            result += bindigits(int(inst[2][1:]),5)
                        else:
                            sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[2]))
                    else:
                        sys.exit("ERROR, line %d: %s argument 2 must be a register" % (linenum,inst[0]))
                    if(inst[3][0] == '#'):
                        nummed = int(inst[3][1:])
                        if(nummed >= 0 and nummed < 512):
                            result += bindigits(int(inst[3][1:]),9)
                        else:
                            sys.exit("ERROR, line %d: branch target address %d is out of range [0-511]" % (linenum,nummed))
                    else:
                        sys.exit("ERROR, line %d: %s argument 3 must be a 9-bit immediate. If you used a $label, this may be an assembler bug." % (linenum,inst[0]))
                    if(inst[4][0] == '#'):
                        nummed = int(inst[4][1:])
                        if(nummed >= 0 and nummed < 8):
                            result += bindigits(int(inst[4][1:]),3)
                        else:
                            sys.exit("ERROR, line %d: branch NCX-subop address %d is out of range [0-7]. If you used a $label, this may be an assembler bug." % (linenum,nummed))
                    else:
                        sys.exit("ERROR, line %d: %s argument 4 must be a 3-bit immediate. If you used a $label, this may be an assembler bug." % (linenum,inst[0]))

                    result += "0"*4

                else:
                    sys.exit("BUG: malformed NCX instruction table while processing line %d" % linenum)


    # else we are a ncx_CP_B
    else:

        # 3 or 4 operands provided?
        if(len(inst)-1 == 3):
            # implicit 1-channel case
            if(inst[1][0] == 'r'):
                nummed = int(inst[1][1:])
                if(nummed >= 0 and nummed < 24):
                    result += bindigits(int(inst[1][1:]),5)
                else:
                    sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
            else:
                sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))
            if(inst[2][0] == 'r'):
                nummed = int(inst[2][1:])
                if(nummed >= 0 and nummed < 24):
                    result += bindigits(int(inst[2][1:]),5)
                else:
                    sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[2]))
            else:
                sys.exit("ERROR, line %d: %s argument 2 must be a register" % (linenum,inst[0]))
            if(inst[3][0] == 'r'):
                nummed = int(inst[3][1:])
                if(nummed >= 0 and nummed < 24):
                    result += bindigits(int(inst[3][1:]),5)
                else:
                    sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[3]))
            else:
                sys.exit("ERROR, line %d: %s argument 3 must be a register" % (linenum,inst[0]))

            result += "0"*5 # gap
            result += "000001" # implicit-ed 1-channel


        # either explicit #chans or 'dense'
        elif(len(inst)-1 == 4):
            if(inst[1][0] == 'r'):
                nummed = int(inst[1][1:])
                if(nummed >= 0 and nummed < 24):
                    result += bindigits(int(inst[1][1:]),5)
                else:
                    sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[1]))
            else:
                sys.exit("ERROR, line %d: %s argument 1 must be a register" % (linenum,inst[0]))
            if(inst[2][0] == 'r'):
                nummed = int(inst[2][1:])
                if(nummed >= 0 and nummed < 24):
                    result += bindigits(int(inst[2][1:]),5)
                else:
                    sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[2]))
            else:
                sys.exit("ERROR, line %d: %s argument 2 must be a register" % (linenum,inst[0]))
            if(inst[3][0] == 'r'):
                nummed = int(inst[3][1:])
                if(nummed >= 0 and nummed < 24):
                    result += bindigits(int(inst[3][1:]),5)
                else:
                    sys.exit("ERROR, line %d: invalid register %s" % (linenum,inst[3]))
            else:
                sys.exit("ERROR, line %d: %s argument 3 must be a register" % (linenum,inst[0]))

            result += "0"*5 # gap

            if(inst[4] == "dense"):
                result += "100000"
            elif(inst[4][0] == '#'):
                nummed = int(inst[4][1:])
                if(nummed > 0 and nummed <= 8):
                    result += "00" # gap
                    result += bindigits(int(inst[4][1:]),4)
                else:
                    sys.exit("ERROR, line %d: invalid number of channels for ncx_CP_B" % linenum)
            else:
                sys.exit("ERROR, line %d: unknown argument %s given to ncx_CP_B" % (linenum,inst[4]))

        else:
            sys.exit("ERROR, line %d: invalid number of arguments given to ncx_CP_B" % linenum)




    return result



##########################################################################################

###################
# Assember Pass 1 #
###################

def pass1(lines):
    labelmap = {}
    # first find the addresses of labels
    ncx_subcount = 0
    total_instcount = 0
    linecnt = 0
    for line in lines:
        resultobj = re.search(r"^([^:]+[:])",line)
        if(resultobj):
            label = str(resultobj.group(0)).split(':')[0]
            instr = str(line.split(':')[1]).split()[0]
            if(instr[0:3] == "pe_"):
                if(ncx_subcount > 0):
                    total_instcount += 1
                    ncx_subcount = 0
                labelmap[label] = (total_instcount, ncx_subcount)
                total_instcount += 1
                ncx_subcount = 0
            elif(instr[0:4] == "ncx_"):
                labelmap[label] = (total_instcount, ncx_subcount)
                ncx_subcount += 1
                if(ncx_subcount == 8):
                    total_instcount += 1
                    ncx_subcount = 0
        else:
            instr = line.split()
            if(instr):
                if(instr[0][0:3] == "pe_"):
                    if(ncx_subcount > 0):
                        total_instcount += 1
                    total_instcount += 1
                    ncx_subcount = 0
                elif(instr[0][0:4] == "ncx_"):
                    ncx_subcount += 1
                    if(ncx_subcount == 8):
                        total_instcount += 1
                        ncx_subcount = 0


    # now substitute $labels with their cisc,risc addresses
    subbedlines = []
    for line in lines:
        # cut out labels
        resultobj = re.search(r"^([^:]+[:])",line)
        if(resultobj):
            rest = str(line.split(':')[1]).split()
        else:
            rest = line.split()
        subbed = []
        for r in rest:
            if(r[0] == '$'):
                if(labelmap[r[1:]]):
                    subbed.append(str("#") + str(labelmap[r[1:]][0]) + ",")
                    subbed.append(str("#") + str(labelmap[r[1:]][1]))
                else:
                    sys.exit("ERROR: label %s not found!" % r[1:])
            else:
                subbed.append(r)
        subbedlines.append(subbed)

    return subbedlines





##########################################################################################

###################
# Assember Pass 2 #
###################

def pass2(lines):

    outhex = open("ne_instructions.hex", 'w')
    outbyte = open("ne_instructions.byte", 'w')
    outbin = open("ne_instructions.bin", 'w+b')
    # used for writing to:
    # ne_inst_total_num_valid_256_hex.txt
    # ne_inst_validbytes.txt
    instr_count = 0


    inside_pe_bracket = False
    ncx_inst_cnt = 0
    ncx_inst_string = ""
    pe_inst_argvect = []
    pe_inst_line_num = 0
    linecnt = 1
    for line in lines:

        if(not line):
            pass
        elif(line[0][0:4] == "ncx_"):
            ncxinst = encode_ncx_inst(line,linecnt)
            ncx_inst_string = ncxinst + ncx_inst_string
            ncx_inst_cnt += 1
            if(ncx_inst_cnt == 8):
                ncx_inst_string = "1001" + bindigits(ncx_inst_cnt,4) + ncx_inst_string
                outhex.write(str(hexify(ncx_inst_string,1)) + "\n")
                outbin.write(bytes.fromhex(hexify(ncx_inst_string,1)))
                for q in range(0,32):
                    outbyte.write("%s" % hexify(ncx_inst_string,0)[(q*2)+1])
                    outbyte.write("%s\n" % hexify(ncx_inst_string,0)[q*2])
                instr_count += 1
                ncx_inst_string = ""
                ncx_inst_cnt = 0
        else:
            for item in line:
                if(item[0:3] == "pe_"):
                    # need to flush any ncx insts outstanding
                    if(ncx_inst_cnt > 0):
                        ncx_inst_string = "1001" + bindigits(ncx_inst_cnt,4) + str(str("0"*31)*(8-ncx_inst_cnt)) + ncx_inst_string
                        outhex.write(str(hexify(ncx_inst_string,1)) + "\n")
                        outbin.write(bytes.fromhex(hexify(ncx_inst_string,1)))
                        for q in range(0,32):
                            outbyte.write("%s" % hexify(ncx_inst_string,0)[(q*2)+1])
                            outbyte.write("%s\n" % hexify(ncx_inst_string,0)[q*2])
                        instr_count += 1
                        ncx_inst_string = ""
                        ncx_inst_cnt = 0

                    # okay, now continue
                    pe_inst_line_num = linecnt
                    pe_inst_argvect.append(item[3:])
                    if(inside_pe_bracket):
                        sys.exit("ERROR, line %d: close bracket } missing for %s" % (linecnt,pe_inst_argvect[0]))
                elif(item == "{"):
                    if(inside_pe_bracket):
                        sys.exit("ERROR, line %d: close bracket } missing for %s" % (linecnt,pe_inst_argvect[0]))
                    inside_pe_bracket = True
                elif(item == "}"):
                    if(not inside_pe_bracket):
                        sys.exit("ERROR, line %d: close bracket } found outside a PE instruction declaration" % linecnt)
                    else:
                        peinst = encode_pe_inst(pe_inst_argvect,pe_inst_line_num)
                        outhex.write(str(hexify(peinst,1)) + "\n")
                        outbin.write(bytes.fromhex(hexify(peinst,1)))
                        for q in range(0,32):
                            outbyte.write("%s" % hexify(peinst,0)[(q*2)+1])
                            outbyte.write("%s\n" % hexify(peinst,0)[q*2])
                        pe_inst_argvect = []
                        inside_pe_bracket = False
                        pe_inst_line_num = 0
                        instr_count += 1
                elif(inside_pe_bracket):
                    if '=' in item:
                        pe_inst_argvect.append(str(item).split('=')[0])
                        pe_inst_argvect.append("=")
                        pe_inst_argvect.append(str(item).split('=')[1])
                    elif(item):
                        pe_inst_argvect.append(item)
                else:
                    sys.exit("ERROR, line %d: cannot understand %s" % (linecnt,item))


        linecnt += 1
        if(instr_count > 511):
            sys.exit("ERROR: too many instructions!")

    if(inside_pe_bracket):
        sys.exit("ERROR: close bracket } missing for PE instruction %s!" % pe_inst_argvect[0])

    # need to flush any ncx insts outstanding
    if(ncx_inst_cnt > 0):
        ncx_inst_string = "1001" + bindigits(ncx_inst_cnt,4) + str(str("0"*31)*(8-ncx_inst_cnt)) + ncx_inst_string
        outhex.write(str(hexify(ncx_inst_string,1)) + "\n")
        outbin.write(bytes.fromhex(hexify(ncx_inst_string,1)))
        for q in range(0,32):
            outbyte.write("%s" % hexify(ncx_inst_string,0)[(q*2)+1])
            outbyte.write("%s\n" % hexify(ncx_inst_string,0)[q*2])
        instr_count += 1
        ncx_inst_string = ""
        ncx_inst_cnt = 0
        if(instr_count > 511):
            sys.exit("ERROR: too many instructions!")

    # fill in gaps to 512 total instruction words
    for i in range(0,512-instr_count):
        outhex.write(str("0"*64) + "\n")
        outbin.write(bytes.fromhex(str("0"*64)))
        for q in range(0,32):
            outbyte.write("00\n")


    # write the files used for faster simulation time (only used for .byte)
    with open("ne_inst_validbytes.txt",'w') as vb:
        for i in range(0,instr_count):
            for j in range(0,32):
                vb.write("1\n")
        for i in range(0,512-instr_count):
            for j in range(0,32):
                vb.write("0\n")
    with open("ne_inst_total_num_valid_256_hex.txt", 'w') as vh:
        vh.write("%x\n" % (instr_count+1))






##########################################################################################

###################
# Main Function   #
###################


with open(args.input) as inputfile:
    lines = inputfile.read()
    lines = re.sub(r"//[^\n]*\n", "\n", lines)
    lines = lines.split('\n')
    subbs = pass1(lines)
    pass2(subbs)
