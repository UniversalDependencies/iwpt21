#!/bin/sh 

cat $1 |grep -v "corresponding" | grep -v "pertains"
