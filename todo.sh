#!/bin/bash

add () {
	name=$1
	echo $name;
	shift

	while getopts ":d:p:t:" opt; do
		case ${opt} in
			d) due=$OPTARG ;;
			p) priority=$OPTARG;;
			t) tags=$OPTARG;;
			?) echo "unknown option";;
		esac
	done

	echo "$name ${due:=$(date -I)} ${priority:=none} ${tags}"  >> $file
}

set () {
	task=$(grep $1 $file)
	shift

	while getopts ":d:p:t:" opt; do
		case ${opt} in
			d) due=$OPTARG;;
			p) priority=$OPTARG;;
			t) tags=$OPTARG;;
		esac
	done

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
		cat $file;;
esac

