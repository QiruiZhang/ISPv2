import argparse

parser = argparse.ArgumentParser(description='Converts a binary text string file into a hex text string file')
parser.add_argument("input", help="Input file to convert")
#parser.add_argument("output", help="Output file name")
args = parser.parse_args()


def decify(binstring):

    dstr = []
    for i in range(0, len(binstring), 8):

        #print(i)
        #print(binstring[i:i+8])
        if(binstring[i] == "1"):
            # neg
            twoscomp = ""
            for j in range(1,8):
                if(binstring[i+j] == "1"):
                    twoscomp = twoscomp + "0"
                else:
                    twoscomp = twoscomp + "1"
            dstr.append(str("-") + str(int(twoscomp,2)+1))
        else:
            dstr.append("FUCK")
            #dstr.append(str(int(binstring[i+7:i],2)))

    return dstr


inf  = open(args.input, "r")
#outf = open(args.output, "w")


for i in inf:
    print(decify(str(i.strip())))
    #outf.write(str(decify(str(i))) + "\n")

inf.close()
#outf.close()
