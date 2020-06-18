import filecmp

file0 = "./03_captures/tb_3_bayer_0600V_0816_1531.bin_raw"
file1 = "./03_captures/tb_3_bayer_0610V_0816_1517.bin_raw"
file2 = "./03_captures/tb_3_bayer_0620V_0816_1456.bin_raw"
file3 = "./03_captures/tb_3_bayer_0623V_0816_1450.bin_raw"
file4 = "./03_captures/tb_3_065V_0816_1401.bin_raw"
file5 = "./03_captures/tb_3_bayer_066V_0816_1408.bin_raw"
file6 = "./03_captures/tb_3_bayer_067V_0816_1420.bin_raw"
file7 = "./03_captures/tb_3_bayer_068V_0816_1430.bin_raw"
file8 = "./03_captures/tb_3_bayer_0691V_0816_1436.bin_raw"
file9 = "./03_captures/tb_3_bayer_0700V_0816_1443.bin_raw"
file10 = "./03_captures/tb_3_bayer_0816_1346.bin_raw"
gold = "./04_goldenbrick/fls_3_gold.txt"

file_list = [file0,file1,file2,file3,file4,file5,file6,file7,file8,file9,file10]

#match0 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file0 ,shallow=False)
#match1 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file1 ,shallow=False)
#match2 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file2 ,shallow=False)
#match3 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file3 ,shallow=False)
#match4 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file4 ,shallow=False)
#match5 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file5 ,shallow=False)
#match6 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file6 ,shallow=False)
#match7 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file7 ,shallow=False)
#match8 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file8 ,shallow=False)
#match9 = filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file9 ,shallow=False)
#match10= filecmp.cmp("./04_goldenbrick/fls_3_gold.txt",file10,shallow=False)

#f0 = open(file0 ,'r')
#f1 = open(file1 ,'r')
#f2 = open(file2 ,'r')
#f3 = open(file3 ,'r')
#f4 = open(file4 ,'r')
#f5 = open(file5 ,'r')
#f6 = open(file6 ,'r')
#f7 = open(file7 ,'r')
#f8 = open(file8 ,'r')
#f9 = open(file9 ,'r')
#f10= open(file10,'r')
#fgold= open(gold,'r')

outfile = open('out.txt','w')
for item in file_list:
	print item
	with open(item) as f0, open(file1) as f1:
		for line0, line1 in zip(f0, f1):
			if line0 != line1:
	 			print >> outfile, "notmatch:" + item
				break

#print match0
#print match1
#print match2
#print match3
#print match4
#print match5
#print match6
#print match7
#print match8
#print match9
#print file10
#print match10
