import argparse

parser = argparse.ArgumentParser(description='Converts a binary text string file into a hex text string file')
parser.add_argument("input", help="Input file to convert")
parser.add_argument("output", help="Output file name")
args = parser.parse_args()



def hexify(binstring):
    hstr = '%0*X' % ((len(binstring) + 3) // 4, int(binstring, 2))
    return hstr


inf  = open(args.input, "r")
outf = open(args.output, "w")


for i in inf:
    outf.write(str(hexify(str(i))) + "\n")

inf.close()
outf.close()
