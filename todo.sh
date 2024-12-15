
#!/bin/bash

function add {
	name="$1"
	tags=()
	# this doesnt work with names with spaces in them
	# e.g. "Task 1" becomes Task, 1
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
				# i.e. the next argument is not a tag
				shift
				while [ $# -gt 0 ]; do
					if echo $1 | grep -qve '--'; then
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
	task=($(grep "^$1" $file | grep -v "complete"))

	c=$(grep "^$1" $file | grep -vc "complete")
	if [ $c -ne 1 ] ; then
		echo "Search failed. Found $c matching entries."
		return 1
	fi
	shift
	tags=(${task[@]:3})

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
					if echo $1 | grep -qve '--'; then
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

	# the exact regex i want here is: "^${task[0]}(?!.*complete)"
	# to remove any line that begins with the relevant task name and ignores all completed tasks
	# but it seems that bash cant do negative lookahead by itself
	# this is still pretty close but it will remove any completed entries of a recurring task
			
	sed -i "" "/^${task[0]}/d" $file
	
	# wouldn't want to append to a file if the previous entry hasn't been removed successfully
	if [ $? -eq 0 ]; then
		echo "${task[@]:0:3} ${tags[@]}" >> $file
		return 0
	fi

	return 1
}

function view {
	# logic for handling sorting and filtering
	# input looks something like ./todo.sh file --view file --due <date> 
	# =shows all tasks due on 1st Dec sorted by priority
	

	
	while [[ $# -gt 0 ]]; do #loops trhough the command line arguments
		case "$1" in #checks if the $1 = viewFile etc
			--viewFile) #command line looks like ./todo.sh <file> --viewFile
				display "$file" #displays the file inputed by the user
				shift
				shift
				;;
			--sort) #command line looks like ./todo.sh <file> --sort <due/priority> <asc/des>
				shift 
    				#checks if the user wants to sort by the date or priority
				if [[ "$1" ==  "due" ]]; then 
					sort_task_date "$file" "$2"  #calls the sort date method passes passing it the file details and des/asc information
				elif  [[ "$1" == "priority" ]]; then
					sort_task_priority "$file" "$2" #calls the sort priority method and passes it the file details and des/asc information
				fi
				shift;;
			--due) #commmand line looks like ./todo.sh <file> --due <date> 
   				#date format = YYYY/MM/DD
				shift
				due_date="$1"
				filter_due_date "$file" "$due_date" #passes the file name and date requested by user to the function
				shift
				;;
			--priority)  #commmand line looks like ./todo.sh <file> --priority <priority level e.g. 'high'>
				shift
				filter_priority "$file" "$1" #passes file name and data requested by user to the function
				shift
				;;
			--tags) #commmand line looks like ./todo.sh <file> --tags <the tag name e.g. 'work'>
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



	return 0

}


function filter_due_date {
#aims to display all the tasks on a date the user has requested

	#intialising variables
	todo_file=$1
	target_date=$2
	high=()
	medium=()
	low=()
	high_counter=0
	medium_counter=0
	low_counter=0


	#checks if the file exists
	if [ ! -f "$todo_file" ]; then
		echo "File '$todo_file' not found!"
		exit 1
	fi

 
	while IFS=' ' read -r task date priority tag #reads line from the file and splits into 4 different fields
	do
		if [ "$date" == "$target_date" ]; then #checks if the date of the tasks is = to the date requested by the user

   			#filtering by priority
			if [ "$priority" == "high" ]; then 
				high[$counter_high]="$task $date $priority $tag" #if the task matches the priority level its added to the array of corresponding to the priority level
				((counter_high++)) #increasig the position in the array
			elif [ "$priority" == "medium" ]; then
				medium[$counter_medium]="$task $date $priority $tag"
				((counter_medium++))
				low[$counter_low]="$task $date $priority $tag"
				((counter_low++))
			fi
		fi
	done < "$todo_file" 

	#calls display function and passes the filename and arrays contained the tasks filtered by date and sorted by priority
	display "$todo_file" "High Priority Tasks:" "${high[@]}"
	display "$todo_file" "Medium Priority Tasks:" "${medium[@]}"
	display "$todo_file" "Low Priority Tasks:" "$low[@]}"

	return 0
}


function sort_task_priority {
#aims to sort all the tasks by the priority level

	#initialising variables
	todo_file="$1"
	order="$2"
	high=()
	medium=()
	low=()
	high_counter=0
	medium_counter=0
	low_counter=0

	#reads every line in the file and splits the data into 4 different fields
	while IFS=' ' read -r task date priority tag
	do
		#filtering by priority
		if [ "$priority" == "high" ]; then 
			high[$counter_high]="$task $date $priority $tag"  #if the task matches the priority level its added to the array of corresponding to the priority level
			((counter_high++)) #increasig the position in the array
		elif [ "$priority" == "medium" ]; then
			medium[$counter_medium]="$task $date $priority $tag"
			((counter_medium++))

		else
			low[$counter_low]="$task $date $priority $tag"
			((counter_low++))
		fi
	done < "$todo_file"





	#sorting by ascending / descending order
 	#sends each of the arrays and filename and what the title of the output is, to the function display
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
#aims to filter tasks by a specific priority defined by the user	

 	#define variables
	todo_file="$1"
	priority_level="$2"
	priorities=()

	#reads every line in the file and splits the data into 4 different fields
	while IFS=" " read -r task date priority tag;
	do
		if [ "$priority" == "$priority_level" ]; then #checks if the priority of a task is = to the specific priority
			priorities+=("$task $date $priority $tag") #if is append it to the array storing the similar priorities
		fi
	done < "$todo_file"

	ToBeDisplayed="Tasks with $priority_level priority"
	display "$todo_file" "$ToBeDisplayed" "${priorities[@]}" #call display function and pass it required arguments

	return 0
}

function display {
#aims to display either an indiviaul files contents or an array containing specific data after being filtered from a file

	#https://stackoverflow.com/questions/17232526/how-to-pass-an-array-argument-to-the-bash-script
	separator="------------------------------------------------------------------"
	todo_file="$1";shift
	displayName="$1"; shift
	array_to_display=("$@") #adds remaining arguments to the array (an arrays contents are passed indiviually)


	#checks if the number of arugments passed to the function is 1
	if [ "$#" -eq 1 ]; then
	echo "$separator"
	echo "Displaying the file $todo_file" #displays contents of the file
	echo "$separator"
	cat "$todo_file"
	echo ""

	elif [ "$#" -gt 1 ]; then #checks if number of arguments is greater than 1
		echo ""
		echo "$separator"
		echo "$displayName" #displays title of the information to be displayed
		echo "$separator"
		for task in "${array_to_display[@]}"; do #loops throuhg the passed array
			echo "     - $task" #displays content of the array
		done
		echo ""
	fi
	echo "$separator"
	return 0
}


function filter_tags {
#aims to display all the tags with a specific filter

 	#defining variables
	todo_file="$1"
	tagToCheck="$2"
	tagged=()

  		
	while IFS=' ' read -r task date priority tag #reads every line in the file and splits into 4 different fields
	do
		if [ "$tagToCheck" ==  "$tag" ]; then #checks if the tag for the task is = to the specific tag
			tagged+=("$task $date $priority $tag") #appends the task to the array storing tasks with the same tag
		fi
	done < "$todo_file"

	ToBeDisplayed="Tasks with the tag $tagToCheck:" 
	display "$todo_file" "$ToBeDisplayed" "${tagged[@]}" #calls the dispaly function with the required arguments

	return 0
}

function sort_task_date {
#aims to sort all the tasks by date	
	#https://www.geeksforgeeks.org/mapfile-command-in-linux-with-examples/ (mapfile) cmd

 	#defining varaibles
 	todo_file="$1"
	order="$2"

	#checks if user wants the information to be displayed in ascending/descending order
	if [[ "$order" == "des" ]]; then
		mapfile -t sorted_tasks < <(sort -t' ' -k2,2 -r "$todo_file")	#sorts the data
		display "$todo_file" "The tasks filtered by date in descending order:" "${sorted_tasks[@]}" #sends the requried data to the display function
	else
		mapfile -t sorted_tasks < <(sort -t' ' -k2,2 "$todo_file")
		display "$todo_file" "The tasks filtered by date in ascending order:" "${sorted_tasks[@]}"
	fi

	return 0
}


function add_tags {
	task=($(grep "^$1" $file | grep -v "complete"))
	c=$(grep "^$1" $file | grep -vc "complete")
	if [ $c -ne 1 ] ; then
		echo "Search failed. Found $c matching entries."
		return 1
	fi
	shift
	tags=(${task[@]:3})

	while [ $# -gt 0 ]; do
		tags=(${tags[@]} $1)
		shift
	done

	set ${task[0]} --tags ${tags[*]}

	return 0
}

function remove_tags {
	task=($(grep "^$1" $file | grep -v "complete"))
	c=$(grep "^$1" $file | grep -vc "complete")
	if [ $c -ne 1 ] ; then
		echo "Search failed. Found $c matching entries."
		return 1
	fi
	shift
	tags=(${task[@]:3})
	
	# doing it this way so each entry is considered seperately
	# e.g. removing "c" from tags "abc bc c" results in "abc bc" not "ab b"
	# does hurt me that the number of iterations is (tags * deletions) not just (no. of deletions)
	# which a replacement like ${tags[@]/delete} would be but whatever
	for delete in $@; do
		for i in ${!tags[@]}; do
			if [[ ${tags[i]} == $delete ]]; then
				unset 'tags[i]'
			fi
		done
	done
	
	set ${task[0]} --tags ${tags[*]}
		
	return 0
}

function complete {
	# logic for completing tasks goes here
	# perhaps this just adds a "complete" tag to the entry? (entries with this tag would be hidden by default when using --view)
	# if completed task has a tag relating to recurrence (ie. "daily" or "weekly") add logic to add a new entry with updated date
	
	# input looks like ./todo.sh file --complete taskName
		
	task=($(grep "^$1" $file | grep -v "complete"))
	c=$(grep "^$1" $file | grep -vc "complete")
	if [ $c -ne 1 ] ; then
		echo "Search failed. Found $c matching entries."
		return 1
	fi
	tags=(${task[@]:3})
	due=${task[@]:1:1}
	
	# this returns true if the complete tag is already within the array of tags

	if [[ " ${tags[*]} " =~ [[:space:]]complete[[:space:]] ]] ; then
		echo "$1 already completed."
		return 1
	fi
	
	tag $1 --add complete
	
	for tag in ${tags[@]}; do
		case $tag in
			# this might be mac exclusive but thats what im working with
			# and it definitely works here
			# the linux equilivant seems to be:
			# due=$(date -d "$due +1d" +"%F") for adding 1 day to the current value of $due
			# or something like that

			daily)
				due=$(date -v +1d -jf "%F" $due "+%F")
				add ${task[0]} --due ${due} --priority ${task[2]} --tags ${tags[@]::((${#tags[@]}-1))};;	
			weekly)
				due=$(date -v +1w -jf "%F" $due "+%F")
				add ${task[0]} --due ${due} --priority ${task[2]} --tags ${tags[@]::((${#tags[@]}-1))};;
			monthly)
				due=$(date -v +1m -jf "%F" $due "+%F")
				add ${task[0]} --due ${due} --priority ${task[2]} --tags ${tags[@]::((${#tags[@]}-1))};;
		esac
	done

	return 0
}

function calendar {

 	todo_file="$1"
  	month=${2:-$(date +%m)}
   	year=${3:-$(date +%Y)}

    	if [ ! -f "$todo_file" ]; then
     		echo "File '$todo_file' not found"
       		exit 1
	fi

 	tasks=$(awk -v month="$month" -v year="$year" '
  		BEGIN { FS =" " }
    		{
      			split($2, date_parts, "-")
	 		if (date_parts[1] == year && date_parts[2] == sprintf("%2d", month)) {
    				print $2
			}
   		}
     	' "$todo_file")

    	echo ""
    	echo "Tasks for $month/$year:"
     	cal "$month" "$year" | awk -v tasks="$tasks" '
      		BEGIN { split(tasks, task_list, "\n") }
		{
  			# Highlight dates with tasks 
     			for (i in task_list) {
				task_date = task_list[i]
    				task_day = int(substr(task_date, 9, 2)) 

 				if ($0 ~ "\\<"task_day"\\>") {
     					gsub("\\<"task_day"\\>", task_day"*")
	  			}
      			}
	 		print
    		}
      	'
       echo ""
       echo "Key: *indicates due tasks"
      

function tag {
	case $2 in
		--add)
			add_tags $1 ${@:3};;
		--remove)
			remove_tags $1 ${@:3};;
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
	sed -i "" "/^$1/d" $file
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
  	--calendar)
   		shift
     		calendar $@ ;;
	*)
		echo "Unknown option: $1"
		exit 1 ;;

esac

if [ $? -eq 1 ]; then
	# functions return 1 if they print their own error message
	exit 1
elif [ $? -gt 1 ]; then
	# generic error message if function returns > 1 (hopefully unused)
        echo "Something went wrong."
	exit 2
fi

exit 0
