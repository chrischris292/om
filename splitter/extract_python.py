#!/usr/bin/python
'''
A tool to extract only MCE data.
Author: saurabhjha2010@gmail.com

'''
from multiprocessing import Pool
import os,sys
def filter(inp):
	print("\n PROCESSING FILE %s" % (inp))
	ifh = open(inp, 'r')
	mce_fh = open(inp+"_mce", 'w')
	gpu_fh = open(inp+"_gpu", 'w')
	mc_fh = open(inp+"_mc_",'w')
#	msgs = ifh.readlines()
	for msg in ifh:
		temp = msg
		msg = msg.split(' ')[8:]
		msg = " ".join(msg)
		if "MCE" in msg:
			mce_fh.write(temp)
		elif "GPU" in msg:
			gpu_fh.write(temp)
		elif ("Machine Check Exception" in msg and "CPU" in msg and "Bank" in msg) or ("TSC" in msg) or ("PROCESSOR" in msg and "SOCKET" in msg and "APIC" in msg):
			mc_fh.write(temp)
			
	mce_fh.close()
	gpu_fh.close()
	mc_fh.close()
	ifh.close()
	print("DONE %s" %(inp))
		

def main():
	#print("start extraction")
	if len(sys.argv) < 3:
		print("Atleast 3 args required")
		return
    	numThreads = int(sys.argv[1])
    	if numThreads > 32:
        	numThreads = 32
	input_files = sys.argv[2:]
	numFiles = len(input_files)

	if numFiles < numThreads:
		numThreads = numFiles

	P = Pool(numThreads)
#	for input_file in input_files:
#		filter(input_file)
	P.map(filter, input_files)

if __name__ == '__main__':
	main()
