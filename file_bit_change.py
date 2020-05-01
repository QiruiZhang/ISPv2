
def file_bit_change(filename="./sample.txt",length=8,indexing=1):
	f  = open(filename,'r')
	if indexing == 1:
		fw = open(filename+'.mod','w')

	vec = []	
	cnt = 1
	line_cnt = 1
	buf = ""
	for line in f:
		buf = line.strip() + buf
		if cnt % length == 0 :
			if indexing == 1:
				print >> fw, "line_cnt: "+ str(line_cnt) + "\t" + buf
			else :
				vec.append(int(buf,2))
			line_cnt = line_cnt +1
			buf = ""
		cnt = cnt+1
	
	f.close()
	if indexing == 1:
		fw.close()
	return vec

if __name__ == '__main__':
	filename = str(raw_input("file_name:   "))
	length   = int(raw_input("length:      "))
	indexing = int(raw_input("indexing?:   "))
	file_bit_change(filename,length,indexing)
