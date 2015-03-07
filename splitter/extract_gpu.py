#!/usr/bin/python
'''
A tool to extract only MCE data.
Author: saurabhjha2010@gmail.com

'''

from pyspark import SparkConf, SparkContext
from multiprocessing import Pool
import os,sys


def filter_gpu(msg):
	temp = msg.split(' ')[8:]
	temp = (" ".join(temp)).lower()
	if "gpu" in temp:
		return msg
def spark_filter(input_files, master):

	conf = (SparkConf().setMaster(master).setAppName("MCE Extractor"))
	sc = SparkContext(conf = conf)
	for lfile in input_files:
		name = lfile.split('/')[len(lfile.split('/')) - 1]
		print("\n\n\nProcessing %s" % (lfile))
		logRDD = sc.textFile(lfile)
		gpuRDD = logRDD.filter(lambda line: filter_gpu(line))
		gpuRDD.saveAsTextFile("hdfs://ac49/users/saurabh/results/" +name + "_gpu")
		

	
def main():
	#print("start extraction")
	if len(sys.argv) < 3:
		print("Atleast 2 args required <spark-url> <files>")
		return
	input_files = sys.argv[2:]
	spark_filter(input_files,sys.argv[1])

if __name__ == '__main__':
	main()
