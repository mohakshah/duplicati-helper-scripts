#!/bin/bash

###########################################################
#        duplicati-report-card.sh by Mohak Shah           #
#                                                         #
# A simple script that prints a report card of the last   #
# duplicati operation to the stdout. A script called by   #
# duplicati's --run-script-after could in-turn call this  #
# script and write its output to a file, email it to you, #
# post it on the web, etc.                                #
# When called after a backup, if $DUPLICATI_CLI_PATH is   #
# set to the path of duplicati-cli, the script also       #
# prints out a list of files added, updated or deleted in #
# the last backup                                         #
###########################################################

echo "Backup Name: $DUPLICATI__backup_name"
echo "Operation: $DUPLICATI__OPERATIONNAME"

if [[ -f "$DUPLICATI__RESULTFILE" ]]; then
    echo "======================================================"
    echo "================== Result File:  ====================="
    echo "======================================================"
    cat "$DUPLICATI__RESULTFILE"

    echo -en '\n\n'


    # List the files added, updated or deleted in the last backup
    if [ ! -z "$DUPLICATI_CLI_PATH" ] && [ $DUPLICATI__OPERATIONNAME == "Backup" ] && \
    grep -qs '^ParsedResult: Success$' "$DUPLICATI__RESULTFILE"; then
        echo "======================================================"
        echo "=============== List of Changes: ====================="
        echo "======================================================"

        "$DUPLICATI_CLI_PATH" compare file://foo --dbpath=$DUPLICATI__dbpath --verbose

        echo -en '\n\n'
    fi
fi

if [[ -f "$DUPLICATI__log_file" ]]; then
    echo "======================================================"
    echo "=================== Log File:  ======================="
    echo "======================================================"
    cat "$DUPLICATI__log_file"

    echo -en '\n\n'
fi

if [[ -f "$DUPLICATI__backend_log_database" ]]; then
    echo "======================================================"
    echo "============= Backend Log Database:  ================="
    echo "======================================================"
    cat "$DUPLICATI__backend_log_database"
fi
