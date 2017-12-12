f = open("file1.txt","r")
meanerror=0
merror=0
for line in f:
	a=line.split();
	maxerror= (float(a[0])/float(a[1]))*100
	if maxerror > merror:
		merror = maxerror
	meanerror+= (float(a[0])/float(a[1]))*100

print "accuracy=",100-(meanerror/100),merror
