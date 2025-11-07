#!/bin/bash
#
# rename.sh
# Purpose: Small utility to rename files in a directory by replacing a search
#          string with a replacement. Provided as an example of small helper
#          utilities used in the analysis workflow.
#
# WARNING (Documentation-only):
#   This script renames files on disk. It is included for review and should not
#   be executed on real data in the public repo without understanding the
#   consequences.
#
# Example (documentation only):
#   ./rename.sh -s oldtag -r newtag -d ./outputs

# Function to display usage instructions
usage() {
    echo "Usage: $0 -s <search_expression> [-r <replacement_expression>] [-d <directory>]"
    echo "  -s: The expression to search for in the file names."
    echo "  -r: The expression to replace the search expression with (optional)."
    echo "      If not provided, the search expression will be removed."
    echo "  -d: Directory to search in (optional, default is current directory)."
    exit 1
}

# Parse command-line arguments
SEARCH_EXPRESSION=""
REPLACEMENT_EXPRESSION=""
DIRECTORY="."

while getopts "s:r:d:" opt; do
    case $opt in
        s) SEARCH_EXPRESSION="$OPTARG" ;;
        r) REPLACEMENT_EXPRESSION="$OPTARG" ;;
        d) DIRECTORY="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure the search expression is provided
if [ -z "$SEARCH_EXPRESSION" ]; then
    echo "Error: You must provide a search expression with the -s flag."
    usage
fi

# If no replacement is provided, set it to empty (which means removal)
if [ -z "$REPLACEMENT_EXPRESSION" ]; then
    REPLACEMENT_EXPRESSION=""
fi

# Find all files containing the search expression in their names and rename them (non-recursively)
find "$DIRECTORY" -maxdepth 1 -type f -name "*$SEARCH_EXPRESSION*" | while read FILE; do
   # Generate the new file name by replacing the search expression with the replacement (or removing it)
   NEW_FILE=$(echo "$FILE" | sed "s/$(echo "$SEARCH_EXPRESSION" | sed 's/[.[\*^$]/\\&/g')/$REPLACEMENT_EXPRESSION/g")

   # Rename the file if the new file name is different
   if [ "$FILE" != "$NEW_FILE" ]; then
      mv "$FILE" "$NEW_FILE"
      echo "$FILE -> $NEW_FILE"
   fi
done
