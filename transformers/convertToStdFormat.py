#!/usr/bin/python
'''
Author: Saurabh Jha
Email: saurabh.jha.2010@gmail.com
Converts to the format given by Lelio. In future the whole workflow will be modified and the decoder will be implemented in python
'''

import os,sys

global BASE_DIR 
def changeFormatMce(in_file,map_file):
	BASE_DIR = '~/om'
	# node id ---> node type
	node_map = {}
	# node id ----> nid
	nid_map = {}
	mapF = open(map_file, 'r')
	for map in mapF:
		node_map[map.split()[0]] = map.split()[1]
		nid_map[map.split()[0]] = map.split()[2]
	mapF.close()
	
	msgs = open(in_file, 'r')
	op_out = open(in_file+"_formatted", 'w')
	for msg in msgs:
		columns = msg.split(' ')
		timestamp = columns[0]
		location = columns[1]
		facility = columns[2]
		date_time = columns[3]
		date = date_time.split('T')[0]
		time = (date_time.split('T')[1]).split('.')[0]
		node_id = columns[4]
		cx_cy = node_id.split('c')[1]
		chasis = (node_id.split('c')[2]).split('s')[0]
		#print(cx_cy, chasis)
		slot = ((node_id.split('c')[2]).split('s')[1]).split('n')[0]
		node = ((node_id.split('c')[2]).split('s')[1]).split('n')[1]
		node_type =node_map[node_id] #tag using file
		nid = nid_map[node_id]
		log_msg = ' '.join((" ".join(columns[9:])).split())
		#format
		filtered_msg = timestamp + "\t" + date + " " + time + "\t" + node_id + "\t" + node_type + "\t" + cx_cy + "\t"  + chasis + "\t" + slot + "\t" + node + "\t" + nid + "\t" + log_msg
		op_out.write(filtered_msg+'\n' )

	msgs.close()
	op_out.close()
def main():
	if len(sys.argv) < 3:
		print "Usage: ./convert <formatted log file > <node mapping file>"
		return
	changeFormatMce(sys.argv[1],sys.argv[2])
	return

if __name__ == "__main__":
	main()

		
