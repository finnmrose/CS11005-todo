#!/bin/bash

add () {
	name=$1
	# this doesnt work with names with spaces in them
	# ie. "Task 1" becomes Task, 1
	echo $name;
	shift

	while [ $# -gt 0 ]; do
		echo $1
		case $1 in
			--due)
				due=$2
				shift
				shift;;
			--priority)
				priority=$2
				shift
				shift;;
			--tags)
				# loop through args until one empty or one starts with "--"
				# tags 
				;;
			*)
				echo "Unknown option: $1"
				shift;;
		esac
	done

	echo "$name ${due:=$(date -I)} ${priority:=none} ${tags}"  >> $file
}

set () {
	# a more secure search could be done here
	# ie. searching for a task called "high" would match any task with priority high
	task=$(grep $1 $file)
	shift

	# i don't like how this is exactly the same as add() but adding another function is strange
	# maybe a global current task variable could be used to store parsed information?

	while [ $# -gt 0 ]; do
		case $1 in
			--due)
				# apparently arrays dont work like this but something equivilant needs to happen here
				# but this might be a problem with my outdated version of bash on my mac
				task[1]=$2
				shift
				shift;;
			--priority)
				task[2]=$2
				shift
				shift;;
			--tags)
				;;
			*) echo "Unknown option: $1";;
		esac
	done
	
	for i in $task; do
		echo $i
	done
	
	# logic for actually replacing task needs to be done here
	echo "${task}"

}

view () {
	# logic for handling sorting and filtering goes here
	# input looks something like ./todo.sh file --view --due 2024-12-1 --sort priority
	# should show all tasks due on 1st Dec sorted by priority

	cat $file
}

complete () {
	# logic for completing tasks goes here
	# perhaps this just adds a "complete" tag to the entry? (entries with this tag would be hidden by default when using --view)
	# or it can remove the entry and add it to a seperate file?
	# these are all part of the bonus feature about archiving completed tasks though so we could just do neither
	# if completed task has a tag relating to recurrence (ie. "daily" or "weekly") add logic to add a new entry with updated date
	
	return 0;
}


if [ $# -lt 2 ] ; then
	echo "Too few arguments."
	exit 1
fi

file=$1
shift

case $1 in
	--add)
		shift
		add $@;;
	--set)
		shift
		set $@;;
	--view) 
		shift
		view $@;;
	--complete)
		shift
		complete $@;;
esac

