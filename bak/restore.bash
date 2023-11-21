#!/bin/bash

source config.bash

# year input

year_dir=`ls $script_dir/backups`
year_list=()

# list possible year choices
echo
echo "***** possible year choices: *****"
echo
for i in $year_dir
do
	year_list+=("$i")
	echo "$i"
done
echo

# what year do we restore from?
echo "***** what year do we restore from? *****"
read year

# check if value is in the array
if [[ " ${year_list[*]} " =~ " ${year} " ]]; then
    echo "***** year accepted *****"
else
	echo
	echo "***** you inserted a wrong year to restore from *****"
	echo
	/bin/bash /etc/bak/restore.bash
        exit 1
fi

#
# week input
#

week_dir=`ls $script_dir/backups/$year`
week_list=()

# list possible week choices
echo 
echo "***** possible week choices: *****"
echo
for i in $week_dir
do
	if test -d $script_dir/backups/$year/$i; then
		
		if test -f $script_dir/backups/$year/$i/monthInfo; then 
		
		monthInfo=$(cat backups/$year/$i/monthInfo)
		dayInfo=$(cat backups/$year/$i/dayInfo)
                week_list+=("$i")
                
		echo week "$i" months: "$monthInfo" days: "$dayInfo"
		fi
	fi
done
echo

# what week do we restore from [weeks start form 0]?
echo "***** what week do we restore from? [insert just a number] *****"
read week


# check if value is in the array
if [[ " ${week_list[*]} " =~ " ${week} " ]]; then
    	echo
	echo "***** week accepted *****"
	echo
else
        echo
        echo "***** you inserted a wrong week to restore from *****"
        echo
        /bin/bash /etc/bak/restore.bash
        exit 1
fi

# if week is previous, download it
if [ "$week" -ne "$weekCounter" ]; then
	echo "***** download started... *****"
		
	cd "$script_dir/backups/$year/$week"

	ftp -inv $HOST <<EOF
user $USER $PASSWORD
cd "$script_dir/backups/$year/$week"
binary
mget *
bye
EOF
	cd "$script_dir"

	#rsync -d -r -e "ssh -o StrictHostKeyChecking=no" backups@192.168.50.105:/$script_dir/backups/$year/$week /$script_dir/backups/$year/$week
fi

# day input

day_dir=$(ls $script_dir/backups/$year/$week)
day_list=()
counter_list=()
tmp=0

# list possible year choices
echo 
echo "***** possible day choices *****"
echo
for i in $day_dir
do
	if [[ $i == *.tar ]]; then
        day_list+=("$i")
	counter_list+=("$tmp")
        echo "$i"
	tmp=$((tmp + 1))
	fi
done
echo

# what day do we restore from?
echo "the scheme is: <day of the week>_<day>_<month>_<restore counter>"
echo
echo "***** what day do we restore from? [insert restore counter]*****"
echo
read day

# check if value is in the array
if [[ " ${counter_list[*]} " =~ " ${day} " ]]; then
        echo
        echo "***** day accepted *****"
        echo
else
        echo
        echo "***** you inserted a wrong day to restore from *****"
        echo
        /bin/bash /etc/bak/restore.bash
        exit 1
fi

# find the right file

selected_tar="$script_dir/backups/$year/$week/*_$day.tar"

# are you sure?
echo Data to be restored:
echo year : $year
echo week : $week
echo date : $(stat -c '%y' $selected_tar)
echo file : $selected_tar

# prompt to contunue / abort
echo
echo "***** Are you sure? [type y/Y to continue] *****"
read decision

if [[ $decision == "y" ]] || [[ $decision == "Y" ]]; then
	echo 
	echo "***** restore process started... *****"
	echo

	# get the array with numbers to restore
	counter_list_length="${#counter_list[@]}"
	for i in ${counter_list[*]}
	do
		if [ "$day" -ge "$i" ]; then
			# echo this guy to a variable
			tar_to_recover=$( echo $script_dir/backups/$year/$week/*_$i.tar)
			tar -b 64 --directory=/ --extract --verbose --file=$tar_to_recover --listed-incremental=/dev/null

			# bring back mysql
			if [ "$i" -eq 0 ]; then
				mysql -u root -p1234 -e "drop database wordpress"
				mysql -u root -p1234 -e "create database wordpress"

				mysql -u root -p1234 wordpress < /etc/bak/mariadb/full_backup$week.sql
			else
				bin_file=$( echo /etc/bak/mariadb_logs/mysql-bin.*$i )
				mysqlbinlog $bin_file | mysql -u root -p1234 wordpress
			fi

		fi
	done
	# delete the unwanted backups from wpServer machine
	rm -rf "$script_dir/backups/$year/$week/*.tar"

else
	echo
	echo "***** restore aborted *****"
	echo
	exit 0
fi
