
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
	# input looks something like ./todo.sh file --view file --due <date> 
	# which should show all tasks due on 1st Dec sorted by priority
	# try implementing ascending / descending sorting
	# also could try and make it look pretty






	#PLAN:
	#allow for users to sort each of the catogories by due date or priority
	#if a user has asked for a file to be sorted sort then display
	#else just use the display 
	#should make the display function able to display the output of arrays - COMPLETE
	#would be the code more effiecent and readable - COMPLETE
	#potentially only use the display to output things to the user - COMPLETE


	while [[ $# -gt 0 ]]; do
		case "$1" in
			--viewFile)
				display "$file"
				echo "Arguments: $@"
				shift
				shift
				;;
			--sort)
				shift
				if [[ "$1" ==  "due" ]]; then
					sort_task_date "$file" "$2"  #make due date filter
				elif  [[ "$1" == "priority" ]]; then
					sort_task_priority "$file" "$2"
				fi
				shift;;
			--due)
				shift
				due_date="$1"
				filter_due_date "$file" "$due_date"
				shift
				;;
			--priority)
				shift
				filter_priority "$file" "$1"
				shift
				;;
			--tags)
				shift
				filter_tags "$file" "$1"
				shift
				;;
			*)
				echo "Unknown option: $1"
				shift
				;;
		esac
	done

	
	




	#everything works when i use cmd  ./todo.sh todo.txt --view todo.txt --due <date>
	#but then i get the final error message
	#now i need to sort it by priority
	#if priority == high
	#then store $task in  the high array
	#3 arrays - high, medium, low
	#the priority of the task corrsponds to the array
	#store the task name in the corresponding array
	#display the arrays in order (high, med etc)
	#implement ascending order
	#progresssssssss


	return 0

}


function filter_due_date {

	todo_file=$1
	target_date=$2
	high=()
	medium=()
	low=()
	high_counter=0
	medium_counter=0
	low_counter=0



	if [ ! -f "$todo_file" ]; then
		echo "File '$todo_file' not found!"
		exit 1
	fi
	
	while IFS=' ' read -r task date priority tag
	do
		if [ "$date" == "$target_date" ]; then

			if [ "$priority" == "high" ]; then
				high[$counter_high]="$task $date $priority $tag"
				((counter_high++))
			elif [ "$priority" == "medium" ]; then
				medium[$counter_medium]="$task $date $priority $tag"
				((counter_medium++))
				low[$counter_low]="$task $date $priority $tag"
				((counter_low++))
			fi
		fi
	done < "$todo_file"


	display "$todo_file" "High Priority Tasks:" "${high[@]}"
	display "$todo_file" "Medium Priority Tasks:" "${medium[@]}"
	display "$todo_file" "Low Priority Tasks:" "$low[@]}"

	return 0
}

#define tasks as all the content in the file
#loop for the lenght of tasks
#if asc/des
#asc if priority = high top of array
#to do this we would
#go through the tasks array if high place in array
#loop through again if prioity = medium place in array
#etc
#for des vice versa

function sort_task_priority {

	todo_file="$1"
	order="$2"
	high=()
	medium=()
	low=()
	high_counter=0
	medium_counter=0
	low_counter=0

	while IFS=' ' read -r task date priority tag
	do

		if [ "$priority" == "high" ]; then
			high[$counter_high]="$task $date $priority $tag"
			((counter_high++))
		elif [ "$priority" == "medium" ]; then
			medium[$counter_medium]="$task $date $priority $tag"
			((counter_medium++))

		else
			low[$counter_low]="$task $date $priority $tag"
			((counter_low++))
		fi
	done < "$todo_file"






	if [[ "$order" == "asc" ]]; then
		echo ""
		echo "Displaying the tasks via ascending priority"
		display "$todo_file" "Priority low:" "${low[@]}"
		display "$todo_file" "Priority medium:" "${medium[@]}"
		display "$todo_file" "Priority high:" "${high[@]}"
	elif [[ "$order" == "des" ]]; then
		echo ""
		echo "Displaying the tasks via descending priority"
		display "$todo_file" "Priority high:" "${high[@]}"
		display "$todo_file" "Priority medium:" "${medium[@]}"
		display "$todo_file" "Priority low:" "${low[@]}"
	fi


	return 0
}

function filter_priority {

	todo_file="$1"
	priority_level="$2"
	priorities=()

	while IFS=" " read -r task date priority tag;
	do
		if [ "$priority" == "$priority_level" ]; then
			priorities+=("$task $date $priority $tag")
		fi
	done < "$todo_file"

	ToBeDisplayed="Tasks with $priority_level priority"
	display "$todo_file" "$ToBeDisplayed" "${priorities[@]}"

	return 0
}

function display {
	#https://stackoverflow.com/questions/17232526/how-to-pass-an-array-argument-to-the-bash-script
	separator="------------------------------------------------------------------"
	todo_file="$1";shift
	displayName="$1"; shift
	array_to_display=("$@")

	if [ "$#" -eq 1 ]; then
	echo "$separator"
	echo "Displaying the file $todo_file"
	echo "$separator"
	cat "$todo_file"
	echo ""

	elif [ "$#" -gt 1 ]; then
		echo ""
		echo "$separator"
		echo "$displayName"
		echo "$separator"
		for task in "${array_to_display[@]}"; do
			echo "     - $task"
		done
		echo ""
	fi
	echo "$separator"
	return 0
}


function filter_tags {

	todo_file="$1"
	tagToCheck="$2"
	tagged=()
	while IFS=' ' read -r task date priority tag
	do
		if [ "$tagToCheck" ==  "$tag" ]; then
			tagged+=("$task $date $priority $tag")
		fi
	done < "$todo_file"

	ToBeDisplayed="Tasks with the tag $tagToCheck:"
	display "$todo_file" "$ToBeDisplayed" "${tagged[@]}"

	return 0
}

function sort_task_date {
	#https://www.geeksforgeeks.org/mapfile-command-in-linux-with-examples/ (mapfile) cmd
	todo_file="$1"
	order="$2"

	if [[ "$order" == "des" ]]; then
		mapfile -t sorted_tasks < <(sort -t' ' -k2,2 -r "$todo_file")
		display "$todo_file" "The tasks filtered by date in descending order:" "${sorted_tasks[@]}"
	else
		mapfile -t sorted_tasks < <(sort -t' ' -k2,2 "$todo_file")
		display "$todo_file" "The tasks filtered by date in ascending order:" "${sorted_tasks[@]}"
	fi

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
	
	for arg in $@; do
		# this shit doesn't work!!!
		# not that it would even be logically correct if it did
		tags=${tags//$arg}
	done

	echo ${tags[*]}
	
	# set ${task[0]} --tags ${tags[*]}
		
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

function remove {
	sed -i "" "/$1/d" $file
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
		add $@ ;;
	--set)
		shift
		set $@ ;;
	--view)
		shift
		view $@ ;;
	--complete)
		shift
		complete $@ ;;
	--search)
		shift
		search $@ ;;
	--tags)
		shift
		tag $@ ;;
	--remove)
		shift
		remove $@ ;;
	*)
		echo "Unknown option: $1"
		exit 1 ;;

esac

if [ $# -gt 0 ]; then
	echo "Something went wrong."
	exit 1
fi




