#!/usr/bin/python
'''
Author: Saurabh Jha
Email: saurabh.jha.2010@gmail.com
Converts to the format given by Lelio. In future the whole workflow will be modified and the decoder will be implemented in python
'''

import os,sys

node_map = {}
nid_map = {}
node_map_old = {}
nid_map_old = {}

def node_mapper(new_map, old_map):
 	# node id ---> node type
	global	node_map
	global node_map_old 
	# node id ----> nid
	global nid_map
	global nid_map_old
	mapF = open(new_map, 'r')
	for map in mapF:
		node_map[map.split()[0]] = map.split()[1]
		nid_map[map.split()[0]] = map.split()[2]
	mapF.close()
	#load old mapping
	mapF = open(old_map, 'r')
	for map in mapF:
		node_map_old[map.split()[0]] = map.split()[1]
		nid_map_old[map.split()[0]] = map.split()[2]
	mapF.close()
	
def changeFormatMce(new_map, old_map, in_file):

	global node_map
	global node_map_old
	global nid_map
	global nid_map_old
	node_mapper(new_map, old_map)
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
		try:
			if int(timestamp) > 1373886000:
				#use new mapping
				node_type =node_map[node_id] #tag using file
				nid = nid_map[node_id]
			else:
				node_type = node_map_old[node_id]
				nid = nid_map_old[node_id]
		except:
			node_type = node_id
			nid = 0
	
		log_msg = ' '.join((" ".join(columns[9:])).split())
		#format
		filtered_msg = timestamp + "\t" + date + " " + time + "\t" + node_id + "\t" + node_type + "\t" + cx_cy + "\t"  + chasis + "\t" + slot + "\t" + node + "\t" + nid + "\t" + log_msg
		op_out.write(filtered_msg+'\n' )

	msgs.close()
	op_out.close()
def main():
	if len(sys.argv) < 4:
		print "Usage: ./convert < new node mapping file> <old node mapping file> <one or more formatted logs>"
		return
	changeFormatMce(sys.argv[1],sys.argv[2], sys.argv[3])
	return

if __name__ == "__main__":
	main()

		
