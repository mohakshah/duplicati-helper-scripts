#!/bin/bash

# List of zfs datasets whose snapshots will be taken.
# These should be the names of datasets _not_ there mountpoints.
# e.g. tank/pictures instead of /media/tank/pictures
datasets=()

# List of mountpoints where the latest snapshots of $datasets will be mounted 
# using mount's --bind option. 
# In case of macOS, existing file/directory will be _deleted_ and a symlink to
# the snapshot will be created instead
snapshot_mountpoints=()

# Each snapshot will be a randomly generated name prefixed with $snapshot_prefix
# You must ensure that you don't use this prefix for naming your own snapshots
# since snapshots with this prefix are deleted automatically by this script.
snapshot_prefix="duplicati-"

delete_old_snapshots=""

is_osx=""
if [[ "$(uname)" == "Darwin" ]]; then
	is_osx="true"
fi

#################################################
################## Functions ####################
#################################################
printHelp() {
	true
	# todo: implement
}

main() {
	#################################################
	############## Sanity Checks ####################
	#################################################
	
	datasets_length=${#datasets[@]}

	if [[ $datasets_length -lt 1 ]]; then
		echo "No dataset provided!" >&2
		printHelp
		return 1
	fi

	if [[ $datasets_length -ne ${#snapshot_mountpoints[@]} ]]; then
		echo "Invalid configuration! No. of \$datasets is not the same as the no. of \$snapshot_mountpoints." >&2
		return 1
	fi

	if [[ x"$snapshot_prefix" == x ]]; then
		echo "Invalid configuration! \$snapshot_prefix cannot be empty." >&2
		return 1
	fi

	echo "Unmounting all the snapshots from there mountpoints..."
	for mp in "${snapshot_mountpoints[@]}"; do
		umount "$mp"
	done

	# delete any previous snapshots having the "$snapshot_prefix", if requested
	if [[ "$delete_old_snapshots" == "true" ]]; then
		echo "Pruning old snapshots."

		for ds in "${datasets[@]}"; do
			while read old_snapshot; do
				echo "Deleting $old_snapshot"
				[ "$is_osx" == true ] && zfs unmount "$old_snapshot"
				zfs destroy "$old_snapshot"
			done < <(zfs list -o name -Ht snapshot | egrep '^'"$ds"'@'"$snapshot_prefix"'.*$')
		done

		echo "Done!"
	fi
}



# parse options
while [[ "$1" ]]; do
	case "$1" in
	 	-p|--snapshot-prefix )
			snapshot_prefix="$2"
			shift; shift
			continue
	 		;;

	 	-d|--delete )
			delete_old_snapshots="true"
			shift
			continue
			;;

	 	* )
			break
			;;
	esac
done

# parse datasets and mountpoints
while [[ "$1" ]]; do
	if [[ -z "$2" ]]; then
		echo "Error! Missing mountpoint for dataset $1." >&2
		printHelp
		exit 1
	fi

	datasets+=("$1")
	snapshot_mountpoints+=("$2")

	shift; shift
done

main "$@"