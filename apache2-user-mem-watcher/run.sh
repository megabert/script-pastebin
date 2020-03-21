#!/bin/bash

log=/tmp/apache2_php_mem_check.log 

while :; do 
	# single run: 3 hours
	# 240 runs -> 720 hours => 30 days in one log file
        for((x=1;x<240;x++));do
                /usr/bin/php apache2-user-mem-watcher
        done 2>&1 | tee $log 
done 

