#!/usr/bin/python
'''
A tool to extract only MCE data.
Author: saurabhjha2010@gmail.com

'''

from pyspark import SparkConf, SparkContext
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
		
def filter_mce(msg):
	if ("Machine Check Exception" in msg and "CPU" in msg and "Bank" in msg) or ("TSC" in msg) or ("PROCESSOR" in msg and "SOCKET" in msg and "APIC" in msg):
		return(msg)

def filter_gpu(msg):
	temp = msg.split(' ')[8:]
	temp = " ".join(temp)
	if "GPU" or "gpu" in temp:
		return msg
def spark_filter(input_files, master):
	conf = (SparkConf().setMaster(master).setAppName("My app"))
	sc = SparkContext(conf = conf)
	for lfile in input_files:
		logRDD = sc.textFile(lfile)
		mceRDD = logRDD.filter(lambda line: filter_mce(line))
		gpuRDD = logRDD.filter(lambda line: filter_gpu(line))
		mlogRDD = logRDD.filter(lambda line: "MCE" in line)
		#coalesce(1)
		mceRDD.saveAsTextFile(lfile+"_mce_code")
		gpuRDD.saveAsTextFile(lfile+"_gpu")
		mlogRDD.saveAsTextFile(lfile+"_mlog")
		

	
def main():
	#print("start extraction")
	if len(sys.argv) < 3:
		print("Atleast 2 args required <spark-url> <files>")
		return
	input_files = sys.argv[2:]
	spark_filter(input_files,sys.argv[1])

if __name__ == '__main__':
	main()
