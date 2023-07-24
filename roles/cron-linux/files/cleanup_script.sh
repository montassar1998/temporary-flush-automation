#!/bin/bash

# This shell script performs cleanup operations on temporary and cache files

# Store the paths that were deleted in the script
deletedPaths=(
    "/tmp"
    "/var/tmp"
)

# Function to check if the item exists in the deleted paths
function isItemDeleted {
    for path in "${deletedPaths[@]}"; do
        if [[ "$1" == "$path" || "$1" == "$path"* ]]; then
            return 0
        fi
    done
    return 1
}

# Delete all files in /tmp
rm -rf /tmp/*

# Delete all files in /var/tmp
rm -rf /var/tmp/*

# Remove the user-specific temporary folder
envTemp="$HOME/tmp"
rm -rf "$envTemp"

# Delete additional paths as needed
# ...

# Clear the console screen
clear
