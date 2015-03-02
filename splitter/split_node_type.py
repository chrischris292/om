#!/usr/bin/python
'''
A tool to extract only MCE data.
Author: saurabhjha2010@gmail.com

'''

from pyspark import SparkConf, SparkContext
from multiprocessing import Pool

import os,sys





#global variables
node_map = {}
		
def filter_mce(msg):
	if ("Machine Check Exception" in msg and "CPU" in msg and "Bank" in msg) or ("TSC" in msg) or ("PROCESSOR" in msg and "SOCKET" in msg and "APIC" in msg):
		return(msg)

def filter_gpu(msg):
	temp = msg.split(' ')[8:]
	temp = " ".join(temp)
	if "GPU" or "gpu" in temp:
		return msg
def spark_filter(input_files, master):

	conf = (SparkConf().setMaster(master).setAppName("MCE Extractor"))
	sc = SparkContext(conf = conf)
	for lfile in input_files:
		print("\n\n\nProcessing %s" % (lfile))
		logRDD = sc.textFile(lfile)
		#mceRDD = logRDD.filter(lambda line: filter_mce(line))
		gpuRDD = logRDD.filter(lambda line: filter_gpu(line))
		#mlogRDD = logRDD.filter(lambda line: "MCE" in line)
		#coalesce(1)
		#mceRDD.saveAsTextFile(lfile+"_mce_code")
		gpuRDD.saveAsTextFile(lfile+"_gpu")
		#mlogRDD.saveAsTextFile(lfile+"_mlog")
		
def node_mapper(map_file):
	global node_map
#	node_map = {}
	mapF = open(map_file, 'r')
	for map in mapF:
		node_map[map.split()[0]] = map.split()[1]
	mapF.close()
	node_map["bwsmw1"] = "bwsmw"
	#node_map['bwsmw1']
#	return node_map
		
def experiment(input_files, map_file):
	node_mapper(map_file)
	global node_map
	#print(node_map['c6-11c1s1n3'])
	lfile = open(input_files, 'r')
	for line in lfile:
		print(filter_nodeType_extract(line,['xe','xk','bwsmw']))
	lfile.close()

def filter_nodeType_extract(msg,type,map_file):
	global node_map
	# node id ----> nid
#	node_map = node_mapper(map_file)
	node_id = msg.split()[4]
#	print(node_id)
#	print(msg.split())
	try:	
		node_type = node_map[node_id]
#		print(node_type)	
		if type == "":
			return (node_type,msg)
		elif node_type in type:
#			print ("got here")
			return (node_type,msg)
		return NULL
	except:
		return ("UNK", msg)
		
	
def spark_nodeType_extract(input_files, master, type, map_file):
	node_mapper(map_file)
	print(node_map)	
	conf = (SparkConf().setMaster(master).setAppName("MCE Extractor"))
	sc = SparkContext(conf = conf)
	type = type.split(',')
	numPartitions = len(type)
	for lfile in input_files:
		print("\n\n\nProcessing %s" % (lfile))
		logRDD = sc.textFile(lfile)
		nodemapRDD = logRDD.map(lambda x: filter_nodeType_extract(x,type, map_file)).groupByKey(numPartitions).saveAsTextFile(lfile+"_split_out")
	
	
	
def main():
	#print("start extraction")
	if len(sys.argv) < 3:
		print("Atleast 3 args required <spark-url> <files>")
		return
	input_files = sys.argv[3:]
	spark_nodeType_extract(input_files,sys.argv[1],"xe,xk,service, bwsmw",sys.argv[2])
#	experiment(sys.argv[2],sys.argv[1])
if __name__ == '__main__':
	main()
