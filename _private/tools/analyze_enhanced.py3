#!/usr/bin/env python3

import csv, sys, fileinput


def read_annotations(filename) :
	annotations = {}
	lines = 0
	same = 0
	ud_same = 0 
	enhanced_total = 0
	for line in fileinput.input(filename) :
		try : 
			fields = line.strip().split()
			if fields[1] == 'sent_id' :
				sent_id = fields[3]
				annotations[sent_id] = {}
			#print(sent_id)
			elif fields[1] == "text" :
				True
			elif fields[7] == "_" :  # skip compound tokens 1-2 word ids, no further annotation
				True
			else :
				deprel = fields[6]+':'+fields[7]
				enhanced = fields[8].split('|')
				index = fields[0]
				annotations[sent_id][index] = [deprel,enhanced]
				lines += 1
				match = 0 
				ud_match = 0 
				for edeprel in enhanced :
					if (deprel == edeprel ) :
						match = 1
					if (edeprel.startswith(deprel) or deprel.startswith(edeprel)) :
						ud_match = 1
				if match :
					same += 1
				if ud_match :
					ud_same += 1
				#if not(ud_match) :
				#	print("{} {}".format(deprel,enhanced))
				#	print(line.strip())
 
				#print(enhanced)
				enhanced_total += len(enhanced)
			# if (len(enhanced_rels) > 1) :
			#	print('{}\t{}\t{}'.format(sent_id,index,enhanced_rels))
			#elif deprel != enhanced :
			#	parts = enhanced.split(":")
			#	if (parts[0] != fields[6] or parts[1] != fields[7]) :
			#		print('{}\t{}\t{}'.format(sent_id,index,enhanced))
		except (IndexError) as error :
			True
	print("read {} deprels, {} enhanced deprels (inc {:4.3f}%), {} same ({:4.3f}%), {} ud-same ({:4.3f}%)".format(lines,enhanced_total, (enhanced_total-lines)/lines * 100, same,same/lines * 100, ud_same, ud_same/lines * 100 ))
	#print("{} & {} & {:4.2f} & {:4.2f} & {:4.2f} \\\\".format(filename[0:2], lines, (enhanced_total-lines)/lines * 100, same/lines * 100, ud_same/lines * 100 ))
	print("{} & {} & {:4.2f} & {:4.2f}  \\\\".format(filename[0:9], enhanced_total, (enhanced_total - same)/enhanced_total * 100, (enhanced_total - ud_same)/enhanced_total * 100 ))
	return annotations


read_annotations(sys.argv[1])
