import argparse

parser = argparse.ArgumentParser(description='Flips around the bytes of a macroblocks.mem for the NE-only sim')
parser.add_argument("input", help="Input file to convert")
parser.add_argument("output", help="Output file name")
args = parser.parse_args()


inf  = open(args.input, "r")
outf = open(args.output, "w")


line = inf.readline()
cnt = 1
while line:
    #print("Line: {}: {}".format(cnt, line.strip()))

    stringg = ""
    for i in range(0,32,2):
        stringg = str(line[i]) + str(line[i+1]) + stringg
    outf.write(stringg)
    outf.write("\n")

    line = inf.readline()
    cnt += 1
