#!/bin/bash

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <first_value> <last_value>"
	exit 1
fi

first_value=$1
last_value=$2

# Execute seff with the provided values
for ((i=first_value; i<=last_value; i++)); do
	scancel ${i}
done