
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
				fw.write("line_cnt: "+ str(line_cnt) + "\t" + buf +"\n")
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
	filename = input("file_name:   ")
	length   = input("length:      ")
	indexing = input("indexing?:   ")
	file_bit_change(str(filename),int(length),int(indexing))
