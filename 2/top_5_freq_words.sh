#!/bin/bash

show_help( ){
	echo "Usage of $0:"
	echo "./top_freq_words [LEN OF TOP] [FILE]"
	echo "If [LEN OF TOP] is not specified, 5 is used"
	echo "If [FILE] is not specified, stdin is used"
	echo "If you are use [FILE], specifie of [LEN OF TOP] is necessarily"
	echo "For example:"
	echo "echo "lol kek ji ji ji ji ji a g b d f" | ./top_5_freq_words.sh"
	echo "./top_5_freq_words.sh 4 text.txt"
	echo "echo "lol kek ji ji ji ji ji a g b d f" | ./top_5_freq_words.sh 2"
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	show_help
	exit 0
fi

if  [ "$#" -gt 2 ]; then
	echo "Error! Too much arg!"
	exit 1
fi

if [ "$#" -eq 2 ]; then
	if [ ! -f "$2"]; then
		echo "Error! $2 is not found!"
		exit 1
	fi

	if ! [[ "$1" =~ ^-?[0-9]+$ ]]; then
		echo "Error! $1 is not a int!"
		exit 1
	fi
	
	COUNT_TOP="$1"
	TEXT_SOURCE="$2"
fi

if [ "$#" -eq 1 ]; then
	if ! [[ "$1" =~ ^-?[0-9]+$ ]]; then
                echo "Error! $1 is not a int!"
        	exit 1
	fi
	COUNT_TOP="$1"
	TEXT_SOURCE="/dev/stdin"
fi

if [ "$#" -eq 0 ]; then
	COUNT_TOP=5
	TEXT_SOURCE="/dev/stdin"
fi

echo "Word frequency analysis..."
echo "========================"

cat "$TEXT_SOURCE" | \
tr '[:upper:]' '[:lower:]' | \
tr -sc '[:alpha:]' '\n' | \
grep -v "^$" | \
sort | \
uniq -c | \
sort -nr | \
head -n "$COUNT_TOP"