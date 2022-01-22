#!/usr/bin/env python3

import os
import sys
import datetime

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

def fix_time(lines, delay):
    delay *= 1000

    flag = 0 # idx:0 time:1 text:2
    i = -1
    for l in lines:
        i += 1
        if flag == 0:
            flag = 1
            continue
        elif flag == 1:
            start_time_str = l.split("-->")[0].strip()
            end_time_str = l.split("-->")[1].strip()

            start_time = datetime.datetime.strptime(start_time_str, "%H:%M:%S,%f")
            end_time = datetime.datetime.strptime(end_time_str, "%H:%M:%S,%f")

            start_time += datetime.timedelta(milliseconds=delay)
            end_time += datetime.timedelta(milliseconds=delay)

            result_line = "%s --> %s\n" % (start_time.strftime("%H:%M:%S,%f")[:-3], end_time.strftime("%H:%M:%S,%f")[:-3])
            lines[i] = result_line

            flag = 2
        elif flag == 2:
            if l == "\n":
                flag = 0

def main():
    if len(sys.argv) != 3:
        print("Usage: %s <srt_file> <delay>" % os.path.basename(sys.argv[0]))
        return

    prefix_path = os.path.abspath(sys.argv[0])
    prefix_path = os.path.dirname(prefix_path)

    srt_name = sys.argv[1]
    delay = float(sys.argv[2])
    print("Subtile delay: %f" % delay)

    lines = get_file(srt_name)
    fix_time(lines, delay)
    create_file(srt_name, lines)
    print("Fix srt subtitle times!")

if __name__ == "__main__":
    main()
