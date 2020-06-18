import sys
import re
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("input", help="input filename")
parser.add_argument('-l', '--longword', help='Print 256bit words instead of 1 byte per line', action='store_true')
args = parser.parse_args()


def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
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


def hexify(binstring):
    hstr = '%0*X' % ((len(binstring) + 3) // 4, int(binstring, 2))
    if(args.longword):
        return hstr
    else:
        return hstr[::-1]


def split_instr(string):
    return (x.group(0) for x in re.finditer(r"(ncx_[\S]+\s+([\s\S][0-9]+,\s*)*([\s\S][0-9]+)*([^\n]+)*)|(pe_[A-Z]+\s+\{[^\}]+\})", string))


def pecode(instr, outfile):
    process_kernel_size = 0
    output_kernel_size = 0
    stride = 0
    max_0_avg_1 = 0
    shift_width = 0
    resize_factor = 0
    include_bias = 0
    ic_size = 0
    start_ic = 0
    current_ic = 0
    finish_ic = 0
    oc_size = 0
    start_oc = 0
    current_oc = 0
    finish_oc = 0
    ia_size = 0
    oa_size = 0
    ia_mem_addr_0 = 0
    ia_mem_addr_1 = 0
    ia_mem_dir_0 = 0
    ia_mem_dir_1 = 0
    ia_mem_buffer_0 = 0
    ia_mem_buffer_1 = 0
    oa_mem_addr = 0
    oa_mem_dir = 0
    oa_mem_buffer = 0
    cwram_addr = 0
    ia_row_size = 0
    ia_col_size = 0
    ia_row_start = 0
    ia_col_start = 0
    ia_row_end = 0
    ia_col_end = 0
    conv_clear_finished = 0
    conv_clear_addr = 0
    operation, parameters = instr.split("{")
    operation = re.sub("\s+", "", operation)
    operation = operation.split("_")[1]
    parameters = parameters.splitlines()
    if operation == "CONV":
        opcode = 0
    elif operation == "POOL":
        opcode = 1
    elif operation == "MOV":
        opcode = 2
    elif operation == "ADD":
        opcode = 3
    elif operation == "FC":
        opcode = 4
    elif operation == "RELU":
        opcode = 5
    elif operation == "HUFF":
        opcode = 6
    elif operation == "BIAS":
        opcode = 7
    elif operation == "RESIZE":
        opcode = 8
    elif operation == "DFC":
        opcode = 10
    for parameter in parameters:
        if parameter.find("=") == -1:
            continue
        parameter = parameter.replace(",", "")
        parameter = re.sub("\s+", "", parameter)
        variable, value = parameter.split("=")
        if value[0] == 'r':
            value = int(value.replace("r", ""))
        else:
            value = int(value)
        if variable == "process_kernel_size":
            process_kernel_size = value
        elif variable == "output_kernel_size":
            output_kernel_size = value
        elif variable == "stride":
            stride = value
        elif variable == "max_0_avg_1":
            max_0_avg_1 = value
        elif variable == "shift_width":
            shift_width = value
        elif variable == "resize_factor":
            resize_factor = value
        elif variable == "include_bias":
            include_bias = value
        elif variable == "ic_size":
            ic_size = value
        elif variable == "start_ic":
            start_ic = value
        elif variable == "current_ic":
            current_ic = value
        elif variable == "finish_ic":
            finish_ic = value
        elif variable == "oc_size":
            oc_size = value
        elif variable == "start_oc":
            start_oc = value
        elif variable == "current_oc":
            current_oc = value
        elif variable == "finish_oc":
            finish_oc = value
        elif variable == "ia_size":
            ia_size = value
        elif variable == "oa_size":
            oa_size = value
        elif variable == "ia_mem_addr_0":
            ia_mem_addr_0 = value
        elif variable == "ia_mem_addr_1":
            ia_mem_addr_1 = value
        elif variable == "ia_mem_dir_0":
            ia_mem_dir_0 = value
        elif variable == "ia_mem_dir_1":
            ia_mem_dir_1 = value
        elif variable == "ia_mem_buffer_0":
            ia_mem_buffer_0 = value
        elif variable == "ia_mem_buffer_1":
            ia_mem_buffer_1 = value
        elif variable == "oa_mem_addr":
            oa_mem_addr = value
        elif variable == "oa_mem_dir":
            oa_mem_dir = value
        elif variable == "oa_mem_buffer":
            oa_mem_buffer = value
        elif variable == "cwram_addr":
            cwram_addr = value
        elif variable == "ia_row_size":
            ia_row_size = value
        elif variable == "ia_col_size":
            ia_col_size = value
        elif variable == "ia_row_start":
            ia_row_start = value
        elif variable == "ia_col_start":
            ia_col_start = value
        elif variable == "ia_row_end":
            ia_row_end = value
        elif variable == "ia_col_end":
            ia_col_end = value
        elif variable == "conv_clear_finished":
            conv_clear_finished = value
        elif variable == "conv_clear_addr":
            conv_clear_addr = value
        elif variable != "":
            sys.exit("Unknown field found in PE instruction: %s" % variable)


    pe_code = bininst(opcode, include_bias, max_0_avg_1, process_kernel_size, output_kernel_size, stride, ic_size,\
            start_ic, current_ic, finish_ic, oc_size, start_oc, current_oc, finish_oc, ia_size, ia_row_start,\
            ia_col_start, ia_row_end, ia_col_end, ia_row_size, ia_col_size,\
            oa_size, shift_width, ia_mem_addr_0, ia_mem_dir_0, ia_mem_buffer_0, ia_mem_addr_1, ia_mem_dir_1,\
            ia_mem_buffer_1, oa_mem_addr, oa_mem_dir, oa_mem_buffer, resize_factor, cwram_addr,\
            conv_clear_finished, conv_clear_addr)
    if(args.longword):
        outfile.write("%s\n" % hexify(pe_code))
    else:
        hexxx = hexify(pe_code)
        for q in range(0,32):
            outfile.write("%s" % hexxx[(q*2)+1])
            outfile.write("%s\n" % hexxx[q*2])


def code(instrs):
    instr_count = 0
    subops = 0
    code_256 = "1001" + 252 * "0"
    if(args.longword):
        outfile = open("ne_instructions.hex", 'w')
    else:
        outfile = open("ne_instructions.byte", 'w')
    for instruction in instrs:
        if instruction[0:4] == "ncx_":
            subops += 1
            code_31 = ""
            instruction = instruction.replace("ncx_", "")
            if instruction[:4] == "HALT":
                code_31 += "1" * 5 + "0" * 26
            elif instruction[:4] == "NOOP":
                code_31 += "0" * 31
            else:
                instr, operands = re.split("\s+", instruction, 1)
                operands = re.sub("\s+", "", operands)
                operands = operands.replace("r", "")
                operands = operands.replace("#", "")
                operands = operands.split(',')
                if instr == "ADD":
                    code_31 += "00001"
                elif instr == "SUB":
                    code_31 += "00011"
                elif instr == "MULT":
                    code_31 += "10001"
                elif instr == "MULTS":
                    code_31 += "10011"
                elif instr == "LDS":
                    code_31 += "00111"
                elif instr == "STS":
                    code_31 += "01000"
                elif instr == "AND":
                    code_31 += "10100"
                elif instr == "OR":
                    code_31 += "10101"
                elif instr == "XOR":
                    code_31 += "10110"
                elif instr == "NAND":
                    code_31 += "10111"
                elif instr == "ADDI":
                    code_31 += "00010"
                elif instr == "SUBI":
                    code_31 += "00100"
                elif instr == "MULTI":
                    code_31 += "10010"
                elif instr == "LSR":
                    code_31 += "11000"
                elif instr == "LSL":
                    code_31 += "11001"
                elif instr == "BEQ":
                    code_31 += "01001"
                elif instr == "BNE":
                    code_31 += "01010"
                elif instr == "BLT":
                    code_31 += "01011"
                elif instr == "BGT":
                    code_31 += "01100"
                elif instr == "BLE":
                    code_31 += "01101"
                elif instr == "BGE":
                    code_31 += "01110"
                elif instr == "CP_B":
                    code_31 += "01111"
                elif instr == "CP_W":
                    code_31 += "10000"
                elif instr == "MOV":
                    code_31 += "00101"
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += bindigits(int(operands[1]), 5)
                    code_31 += "0" * 16
                elif instr == "MOVI":
                    code_31 += "00110"
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += "0" * 5
                    code_31 += bindigits(int(operands[1]), 16)

                if instr == "ADD" or instr == "SUB" or instr == "MULT" or instr == "MULTS" or instr == "AND" or \
                        instr == "OR" or instr == "XOR" or instr == "NAND" or instr == "LDS" or instr == "STS":
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += bindigits(int(operands[1]), 5)
                    code_31 += bindigits(int(operands[2]), 5)
                    code_31 += "0" * 11
                elif instr == "ADDI" or instr == "SUBI" or instr == "MULTI" or instr == "LSR" or instr == "LSL":
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += bindigits(int(operands[1]), 5)
                    code_31 += bindigits(int(operands[2]), 16)
                elif instr == "BEQ" or instr == "BNE" or instr == "BLT" or instr == "BGT" or instr == "BLE" or \
                        instr == "BGE":
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += bindigits(int(operands[1]), 5)
                    code_31 += bindigits(int(operands[2]), 9)
                    code_31 += bindigits(int(operands[3]), 3)
                    code_31 += "0" * 4
                elif instr == "CP_B":
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += bindigits(int(operands[1]), 5)
                    code_31 += bindigits(int(operands[2]), 5)
                    code_31 += bindigits(int(0), 5) #removed quant param
                    if(len(operands) < 4):
                        # omitting #chans assumes they mean 1-channel src
                        code_31 += "000001"
                    elif(operands[3] == "dense"):
                        code_31 += "100000"
                    elif(str.isnumeric(operands[3])):
                        code_31 += "00"
                        if(int(operands[3]) >= 1 and int(operands[3]) <= 8):
                            code_31 += bindigits(int(operands[3]),4)
                        else:
                            sys.exit("Invalid number of channels in CP_B")
                    else:
                        sys.exit("Unknown argument given to CP_B")
                elif instr == "CP_W":
                    code_31 += bindigits(int(operands[0]), 5)
                    code_31 += bindigits(int(operands[1]), 5)
                    code_31 += bindigits(int(0), 5) #removed r3
                    code_31 += bindigits(int(0), 5) #removed r4
                    code_31 += "0" * 6
            code_256 = code_256[:255 - subops * 31 + 1] + code_31 + code_256[255 - (subops - 1) * 31 + 1:]
            if subops == 8:
                code_256 = code_256[:4] + "1000" + code_256[8:]
                instr_count += 1
                if instr_count > 512:
                    sys.exit("More than 512 lines of instructions")
                if(args.longword):
                    outfile.write("%s\n" % hexify(code_256))
                else:
                    hexxx = hexify(code_256)
                    for q in range(0,32):
                        outfile.write("%s" % hexxx[(q*2)+1])
                        outfile.write("%s\n" % hexxx[q*2])
                subops = 0
                code_256 = "1001" + 252 * "0"
        elif instruction[0:3] == "pe_":

            if subops > 0:
                code_256 = code_256[:4] + bindigits(subops,4) + code_256[8:]
                instr_count += 1
                if instr_count > 512:
                    sys.exit("More than 512 lines of instructions")
                if(args.longword):
                    outfile.write("%s\n" % hexify(code_256))
                else:
                    hexxx = hexify(code_256)
                    for q in range(0,32):
                        outfile.write("%s" % hexxx[(q*2)+1])
                        outfile.write("%s\n" % hexxx[q*2])
                subops = 0
                code_256 = "1001" + 252 * "0"

            instr_count += 1
            if instr_count > 512:
                sys.exit("More than 512 lines of instructions")
            pecode(instruction, outfile)
        else:
            continue
    if subops > 0:
        code_256 = code_256[:4] + bindigits(subops, 4) + code_256[8:]
        instr_count += 1
        if instr_count > 512:
            sys.exit("More than 512 lines of instructions")
        if(args.longword):
            outfile.write("%s\n" % hexify(code_256))
        else:
            hexxx = hexify(code_256)
            for q in range(0,32):
                outfile.write("%s" % hexxx[(q*2)+1])
                outfile.write("%s\n" % hexxx[q*2])
    if(args.longword):
        padding = ("0" * 64 + "\n") * (512 - instr_count)
        outfile.write(padding)
    else:
        for q in range(0,(512-instr_count)*32):
            outfile.write("00\n")
    outfile.close()
    fd = open('ne_inst_total_num_valid_256_hex.txt', 'w')
    fd.write("%x\n" % (instr_count+1))
    fd.close()
    fd = open('ne_inst_validbytes.txt', 'w')
    for i in range(0, instr_count):
        for j in range(0, 32):
            fd.write("1\n")
    for i in range(0, 512-instr_count):
        for j in range(0,32):
            fd.write("0\n")
    fd.close()


with open(args.input) as inputfile:
    lines = inputfile.read()
    lines = re.sub(r"//[^\n]*\n", "\n", lines)
    instructions = list(split_instr(lines))
    code(instructions)
