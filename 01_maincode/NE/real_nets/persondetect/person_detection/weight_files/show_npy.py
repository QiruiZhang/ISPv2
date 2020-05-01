import numpy as np
import argparse


################################
# This dumps .npy files into a #
# fun and friendly format      #
################################


parser = argparse.ArgumentParser(description='dump HxWxC .npy into text')
parser.add_argument("infile", help="input .npy")
parser.add_argument("--hex", "-H", help="use hex-mode output (only in 3 dim case)", action='store_true')
parser.add_argument("--dims", "-d", help="number of dimensions in input. only 1 to 4 are supported", type=int, default=3)
args = parser.parse_args()

array = np.load(args.infile)

if(args.dims > 4 or args.dims < 1):
    print("ERROR: bad number of dimensions! only 1 to 4 are supported")
    exit(1)

if(args.hex and args.dims != 3):
    print("ERROR: hex only valid for 3 dimension case")
    exit(1)



np.set_printoptions(threshold=np.nan)
print(array.shape)


if(args.hex):
    for i in range(0,array.shape[1]):
        print("Col: [%d]" % i)
        for j in range(0,array.shape[0]):
            for k in range(0,array.shape[2]):
                print(str(format(np.uint8(np.int8(array[j][i][k])), 'x')).zfill(2),end=' ')
            print("")
        print("\n")
else:

    if(args.dims == 1):
        for i in range(0,array.shape[0]):
            print(np.int8(array[i]))

    elif(args.dims == 2):
        for i in range(0,array.shape[0]):
            for j in range(0,array.shape[1]):
                print(np.int8(array[i][j]),end='\t')
            print("")
        print("\n")

    elif(args.dims == 3):
        for i in range(0,array.shape[2]):
            print("Channel: [%d]" % i)
            for j in range(0,array.shape[0]):
                for k in range(0,array.shape[1]):
                    print(np.int8(array[j][k][i]),end='\t')
                print("")
            print("\n")

    elif(args.dims == 4):
        for q in range(0,array.shape[3]):
            print("Filter Set: [%d]" % q)
            for i in range(0,array.shape[2]):
                print("    Channel: [%d]" % i)
                print("    ",end='')
                for j in range(0,array.shape[0]):
                    for k in range(0,array.shape[1]):
                        print(np.int8(array[j][k][i][q]),end='\t')
                    print("\n    ",end='')
                print("\n")
    
