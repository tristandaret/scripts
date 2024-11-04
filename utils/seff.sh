#!/bin/bash

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <first_value> <second_value>"
	exit 1
fi

first_value=$1
second_value=$2

# Execute seff with the provided values
seff "$first_value" "$second_value"
for ((i=first_value; i<=second_value; i++)); do
	seff ${i}
done