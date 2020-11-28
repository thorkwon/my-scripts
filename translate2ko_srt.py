#!/usr/bin/env python3

import sys
import os

def get_file(file_name):
	try:
		f = open(file_name,'r', encoding='UTF8')
		lines = f.readlines()
		f.close()
	except:
		lines = []

	return lines

def create_file(file_name, content):
    file = open(file_name, 'w', encoding='UTF-8')

    for line in content:
        file.write('%s' % line)
    file.close()

def write_text(dests, text, i):
	text_len = len(text)
	while i < text_len:
		dests.append(text[i])
		i += 1
		if i < text_len and text[i] == "\n":
			i += 1
			break

	return i

def merge_prefix_and_text(lines, text):
	result_lines = []
	flag = 0 # idx:0 time:1 text:2
	i = 0

	for line in lines:
		if flag == 0:
			result_lines.append(line)
			flag += 1
		elif flag == 1:
			result_lines.append(line)
			flag += 1
			i = write_text(result_lines, text, i)
		else:
			if line == "\n":
				result_lines.append(line)
				flag = 0

	return result_lines

def get_en_text(lines):
	result_lines = []
	flag = 0 # idx:0 time:1 text:2

	for line in lines:
		if flag == 0:
			flag += 1
		elif flag == 1:
			flag += 1
		else:
			if line == "\n":
				result_lines.append(line)
				flag = 0
			else:
				result_lines.append(line)

	return result_lines

def main():
	if len(sys.argv) == 1:
		print("Usage: python3 %s <srt file>" % os.path.basename(sys.argv[0]))
		return

	prefix_path = os.path.abspath(sys.argv[0])
	prefix_path = os.path.dirname(prefix_path)

	srt_name = sys.argv[1]
	ko_name = srt_name + ".ko"
	en_name = srt_name + ".en"

	lines = get_file(srt_name)

	ko_list = get_file(ko_name)

	if not len(ko_list):
		result_list = get_en_text(lines)
		create_file(en_name, result_list)
		print("Create en text file: %s\n" % en_name)
		print("You have to translate to Korea text " +
				"file and then save to file '%s'" % ko_name)
	else:
		result_list = merge_prefix_and_text(lines, ko_list)
		os.rename(srt_name, srt_name + ".backup")
		print("Backup origin file %s.backup" % srt_name)
		create_file(srt_name, result_list)
		print("Create ko subtitle srt file: %s" % srt_name)

if __name__ == "__main__":
	main()
