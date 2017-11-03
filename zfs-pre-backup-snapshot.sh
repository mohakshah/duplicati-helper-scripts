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

snapshot_id_gen() {
	base64 </dev/urandom | tr -dc A-Za-z0-9 | head -c 16
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

	# get each dataset's mountpoint
	dataset_mountpoints=()
	for ds in "${datasets[@]}"; do
		if [[ x"$ds" == x ]]; then
			echo "Invalid configuration! dataset cannot be empty." >&2
			return 1
		fi

		mp="$(zfs get -Ho value mountpoint "$ds")" || return 2
		if [[ "$mp" == "none" || "$mp" == "legacy" ]]; then
			echo "Mount point of dataset $ds must be set to a valid path. It is currently set to $mp." >&2
			return 2
		fi
		dataset_mountpoints+=("$mp")
	done

	# set the snapdir property to "visible" for each dataset
	for ds in "${datasets[@]}"; do
		zfs set snapdir=visible "$ds" || return 2
	done

	# create a new snapshot of each dataset and mount/symlink it
	for ((i = 0; i < datasets_length; i++)); do
		mountpoint="${snapshot_mountpoints[$i]}"
		snapshot_name="$snapshot_prefix""$(snapshot_id_gen)"
		zfs snapshot "${datasets[$i]}"'@'"$snapshot_name" || return 3
		
		if [[ "$is_osx" == "true" ]]; then
			# os x requires mounting the snapshots first
			zfs mount "${datasets[$i]}"'@'"$snapshot_name"

			# delete if it's a dir
			if [[ -d "$mountpoint" ]]; then
			       rm -rf "$mountpoint" || return 3
		        fi

			# create a symlink
			/bin/ln -sFf "${dataset_mountpoints[$i]}/.zfs/snapshot/$snapshot_name/" "$mountpoint" || return 3
		else
			# delete if $mountpoint is not a directory and create one in place
			if [[ ! -d "$mountpoint" ]]; then rm -f "$mountpoint" && mkdir "$mountpoint" || return 3 ; fi

			mount -o bind "${dataset_mountpoints[$i]}/.zfs/snapshot/$snapshot_name/" "${snapshot_mountpoints[$i]}" || return 3
		fi
	done
}



# parse options
while [[ "$1" ]]; do
	case "$1" in
	 	-p|--snapshot-prefix )
			snapshot_prefix="$2"
			shift; shift
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