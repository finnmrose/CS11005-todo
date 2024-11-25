#!/bin/bash

function add {
	name="$1"
	tags=()
	# this doesnt work with names with spaces in them
	# ie. "Task 1" becomes Task, 1
	shift

	while [ $# -gt 0 ]; do
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
				# loop through args until end or an arg starts with "--"
				shift
				while [ $# -gt 0 ]; do
					# this is not quite right but grep doesn't like "grep "--""
					# but it is good enough for now
					if echo $1 | grep -qv "-"; then
						tags=(${tags[@]} $1)
						shift
					else
						break
					fi
				done
				;;
			*)
				echo "Unknown option: $1"
				return 1;;
		esac
	done

	echo "$name ${due:=$(date -I)} ${priority:=none} ${tags[@]}"  >> $file
	
	return 0
}

function set {
	# a more secure search could be done here
	# ie. searching for a task called "high" would match any task with priority high
	task=($(grep $1 $file))
	shift
	tags=(${task[@]:3})

	# i don't like how this is exactly the same as add() but adding another function is strange
	# maybe a global current task variable could be used to store parsed information?

	while [ $# -gt 0 ]; do
		case $1 in
			--due)
				task[1]=$2
				shift
				shift;;
			--priority)
				task[2]=$2
				shift
				shift;;
			--tags)
				tags=()
				shift
				while [ $# -gt 0 ]; do
					if echo $1 | grep -qv "-"; then
						tags=(${tags[@]} $1)
						shift
					else
						break
					fi
				done
				;;
			*)
				echo "Unknown option: $1"
				return 1;;
		esac
	done
		
	sed -i "" "/${task[0]}/d" $file
	
	# wouldn't want to append to a file if the previous entry hasn't been removed successfully
	if [ $? -eq 0 ]; then
		echo "${task[@]:0:3} ${tags[@]}" >> $file
		return 0
	fi

	return 1
}

function view {
	# logic for handling sorting and filtering goes here
	# input looks something like ./todo.sh file --view --due 2024-12-1 --sort priority
	# which should show all tasks due on 1st Dec sorted by priority
	# try implementing ascending / descending sorting
	# also could try and make it look pretty
	
	cat $file

	return 0
}

function addtags {
	task=($(grep $1 $file))
	shift
	tags=(${task[@]:3})

	while [ $# -gt 0 ]; do
		tags=(${tags[@]} $1)
		shift
	done

	set ${task[0]} --tags ${tags[*]}
	
	return 0
}

function removetags {
	task=($(grep $1 $file))
	shift
	tags=(${task[@]:3})

	# damn this is harder than it looks


	return 0
}

function complete {
	# logic for completing tasks goes here
	# perhaps this just adds a "complete" tag to the entry? (entries with this tag would be hidden by default when using --view)
	# if completed task has a tag relating to recurrence (ie. "daily" or "weekly") add logic to add a new entry with updated date
	
	return 0
}

function tag {
	case $2 in
		--add)
			addtags $1 ${@:3};;
		--remove)
			removetags $1 ${@:3};;
		*)
			echo "Unknown option: $2"
			return 1;;
	esac
	
	return 0
}

function search {
	grep $1 $file

	return 0
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
	--search)
		shift
		search $@;;
	--tags)
		shift
		tag $@;;
esac

if [ $? -gt 0 ]; then
       echo "Something went wrong."
fi


