#!/usr/bin/python

import os, sys, re
import re
from pyspark import SparkConf, SparkContext
import zipfile
import random
nltk_dir = "/home/saurabhjha/.local/lib/python2.6/site-packages/nltk/"

stopwords = []
def load_nltk_stopwords():
	global stopwords
	stopwords = list(open("nltk_stopwords", 'r'))

def cleanup(msg):
	msg = " ".join(msg.split(' ')[8:])
	global stopwords
	msg = msg.lower()
	regex = re.compile('[%s]' % re.escape('!"#$%&\'()*+,./:;<=>?@[\\]^_`{|}~-'))
	msg = regex.sub(' ', msg)
	tokens = msg.split(' ') #nltk.wordpunct_tokenize(unicode(msg, errors='ignore'))
	# Stop word and number filtering
	tokens= [str(t) for t in tokens if str(t) not in stopwords and not str(t).isdigit() and len(str(t))>1 and '0x' not in str(t)]
	return " ".join(tokens)

def ziplib():
        libpath = os.path.dirname(nltk_dir)                  # this should point to your packages directory 
        zippath = '/tmp/mylib-' + str(int(random.random()*1e6)%1000000) + '.zip'      # some random filename in writable directory
        zf = zipfile.PyZipFile(zippath, mode='w')
	print("\n\n\n " + libpath +"\n\n\n")
        try:
       		zf.debug = 3                                              # making it verbose, good for debugging 
        	zf.writepy(libpath)
        	return zippath                                             # return path to generated zip archive
        finally:
        	zf.close()


def spark_get_templates(cluster, type, files):
	global templates

        conf = (SparkConf().setMaster(cluster).setAppName("Template new Generator"))
        sc = SparkContext(conf = conf)
	#zip_path = ziplib()                                               # generate zip archive containing your lib                            
	#sc.addPyFile(zip_path) 

	for lfile in files:
		logRDD = sc.textFile(lfile)
		
		name = lfile.split("/")[(len(lfile.split("/")))-1]
		templateRDD = logRDD.map(lambda msg: (cleanup(msg),1))
		
		reduceRDD = templateRDD.reduceByKey(lambda a, b: a + b)
		reduceRDD.saveAsTextFile("hdfs://ac49/users/saurabh/results/" + type +"/" + name + "/" + "_template_count")
	
def setup():
	load_nltk_stopwords()

def main():
	if len(sys.argv) < 4:
		print("wrong format <cluster> <type> <files>")
		return 
	files = sys.argv[3:]
	cluster = sys.argv[1]
	type = sys.argv[2]
	setup()
	#print(cleanup(sys.argv[3]))
	spark_get_templates(cluster,type,files)

if __name__ == "__main__":
	main()
