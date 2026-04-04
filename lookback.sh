#!/bin/bash

# lookback - A Bash utility to compare files and directories.
readonly LOOKBACK_VERSION="1.0"

# Copyright (c) 2026 Luis Gómez Gutiérrez
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.


# Options
lb_show_help=false
lb_verbose=false
lb_ignore=false
lb_sidebyside=""
lb_save=false
lb_hashfunction="xxhash-128"
lb_appledouble=false

# Parse long-format flags
[[ "$1" == "--version" ]] && { echo "$LOOKBACK_VERSION"; exit 0; }
[[ "$1" == "--help" ]] && lb_show_help=true && shift

# Parse short-format flags
while getopts "vhisyXH:" lb_option
do
	case $lb_option in
		v) lb_verbose=true ;;
		h) lb_show_help=true ;;
		i) lb_ignore=true ;; #ignore folder structure
		s) lb_save=true ;;
		y) lb_sidebyside='-y' ;;
		X) lb_appledouble=true ;;
		H) lb_hashfunction=$OPTARG ;; #accepts "md5" and "xxHash" (default) as arguments
	esac

done
shift "$((OPTIND-1))"

# Help menu (usage)
if [[ $lb_show_help == true ]]
	then
	echo lookback v$LOOKBACK_VERSION. A Bash utility to compare files and directories.
	echo
	echo "Usage: lookback [options] <source> <destination>"
	echo
	echo "Optional flags:"
	echo "  --version : Print version"
	echo "  -h : Print this help message"
	echo "  -v : Verbose"
	echo "  -i : Ignore folder structure"
	echo "  -y : Side-by-side comparison"
	echo "  -s : Save a list of files of the source directory (on the destination directory)"
	echo "  -H <hash> : File comparison using specific hash function: xxHash-128 (default), md5"
	echo "  -X : Show hidden AppleDouble files"
	echo
	exit 0
fi

# Resolve absolute path (if relative path was provided)
function get_abs_path() {
    local path="$1"
    if [[ -d "$path" ]]; then
        echo "$(cd "$path" && pwd)"
    else
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
}

lb_src=$(get_abs_path "$1")
lb_dest=$(get_abs_path "$2")
lb_srcname=$(basename "$1")
lb_destname=$(basename "$2")


# Check input errors
[[ -z "$lb_src" || -z "$lb_dest" ]] && { echo "Error: Source and destination required" && exit 1 ; }
[ "$lb_src" == "$lb_dest" ] && { echo "Error: The two paths provided must be different" && exit 1 ; }


# Case-insensitive conversion for hashfunction
lb_hashfunction=$(echo "$lb_hashfunction" | tr '[:upper:]' '[:lower:]')

# --- File comparison ---
if [ -f "$lb_src" ] && [ -f "$lb_dest" ]; then
	[[ $lb_verbose == true ]] && echo "Comparing checksums of individual files..."
	case $lb_hashfunction in
		md5)
			if command -v md5 >/dev/null; then	# macOS/BSD
				lb_hash1=$(md5 -q "$lb_src")
				lb_hash2=$(md5 -q "$lb_dest")
				else							# Linux/GNU
				lb_hash1=$(md5sum "$lb_src" | cut -d " " -f 1)
				lb_hash2=$(md5sum "$lb_dest" | cut -d " " -f 1)
				fi
			;;
		xxhash-128|xxhash)
			if ! command -v xxhsum >/dev/null; then
				echo "Error: xxhsum not found. Please install xxHash or use md5 (see -h for help menu)." && exit 1
			fi
				lb_hash1=$(xxhsum -H128 "$lb_src" | cut -d " " -f 1)
				lb_hash2=$(xxhsum -H128 "$lb_dest" | cut -d " " -f 1)
			;;
		*) echo "Unsupported hash provided: $lb_hashfunction" && exit 1 ;;
	esac

	if [ "$lb_hash1" == "$lb_hash2" ]; then
		echo && echo "It's a match! Checksums from $(basename "$lb_src") and $(basename "$lb_dest") are identical." && echo
	else
		echo && echo "Calculated hashes are different" && echo
	fi

# --- Directory comparison ---
elif [ -d "$lb_src" ] && [ -d "$lb_dest" ]; then
	#Define exclusion patterns (including AppleDouble files)
	lb_find_exclude=( -type f
		! -iname ".DS_Store"
		! -path "*/.Trashes*"
		! -path "*/.Spotlight-V100*"
		! -path "*/.fseventsd*"
		! -path "*/.DocumentRevisions-V100*"
		#! -iname "Network Trash Folder"
		#! -iname "Temporary Items"
		#! -path "*/Cache*"
		#! -path "*/Caches*"
	)
	[[ $lb_appledouble == false ]] && lb_find_exclude+=( ! -iname "._*" )

	#Define 'stat' flags for portability (detect GNU vs BSD stat)
	if stat --help 2>&1 | grep -q "GNU"; then
		# GNU Stat (Linux or Homebrew coreutils)
		lb_stat_portable=(stat --quoting-style=literal -c "%n %% %s")
	else
		# BSD Stat (default macOS)
		lb_stat_portable=(stat -f "%N %% %z")
	fi


	#Define sorting logic (optionally ignoring folder structure)
	lb_sorting_process="sort"
	[[ $lb_ignore == true ]] && lb_sorting_process="sed 's:.*/::' | sort -u"

	#Verbose
	if [[ $lb_verbose == true ]]; then
		lb_msg="Checking filenames and file sizes..."
		[[ $lb_ignore == true ]] && lb_msg="Ignoring folder structure, checking only filenames and file sizes..."
		[[ $lb_appledouble == true ]] && lb_msg="$lb_msg Showing AppleDouble file differences..."
		echo "$lb_msg"
	fi

	#Execution
	if [[ $lb_save == true ]]; then
		(cd "$lb_src" && find . "${lb_find_exclude[@]}" -exec "${lb_stat_portable[@]}" {} + | eval "$lb_sorting_process") > "$lb_dest/molist_$lb_srcname.log"
		echo "File list saved to $lb_dest/molist_$lb_srcname.log"
	else
		diff $lb_sidebyside \
			<(cd "$lb_src" && find . "${lb_find_exclude[@]}" -exec "${lb_stat_portable[@]}" {} + | eval "$lb_sorting_process") \
			<(cd "$lb_dest" && find . "${lb_find_exclude[@]}" -exec "${lb_stat_portable[@]}" {} + | eval "$lb_sorting_process")
		[ $? -eq 0 ] && echo && echo "It's a match! Filenames and file sizes from $lb_srcname and $lb_destname are matching." && echo
	fi
else
	echo && echo "Input needs to be either two files or two directories on the file system. Type \"lookback -h\" for help." && echo
fi
