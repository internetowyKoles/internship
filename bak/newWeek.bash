#!/bin/bash

source config.bash

# make a dir for year
mkdir -p $app_dir

# change weekCounter
if test -f "$weekCounterFile"; then
	weekCounter="$((`cat $weekCounterFile` + 1))"
        echo "$weekCounter" > $weekCounterFile

        # delete the previous week
        rm -rf $app_dir/"$(($weekCounter - 1))"/*.tar
	#echo $app_dir/"$(($weekCounter - 1))"/*

else
	echo 0 > $weekCounterFile
        weekCounter=0
fi

# make a dir for new week
mkdir -p $app_dir/$weekCounter

# make a dir - mariadb
mkdir -p $script_dir/mariadb

# make a dir - mariadb_logs
mkdir -p $script_dir/mariadb_logs
