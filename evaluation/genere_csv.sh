#!/bin/sh
set -x

rm -f all_from_html.csv
for FILE in `ls work/*html`;do
	cat ${FILE} | grep -P "IWPT|h2|table|td" >> all_from_html.csv
done
