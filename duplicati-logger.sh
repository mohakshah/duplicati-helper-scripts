#!/bin/bash

print_help() {
    true
    # todo: implement!
}

log_file="$1"
if [[ -z "$log_file" ]]; then
    echo "Missing argument!" >&2
    print_help
    exit 1
fi

echo "Operation: $DUPLICATI__OPERATIONNAME" >> "$log_file"

if [[ -f "$DUPLICATI__RESULTFILE" ]]; then
    echo "======================================================" >> "$log_file"
    echo "================== Result File:  =====================" >> "$log_file"
    echo "======================================================" >> "$log_file"
    cat "$DUPLICATI__RESULTFILE" >> "$log_file"

    echo -en '\n\n' >> "$log_file"


    if [ ! -z "$DUPLICATI_CLI_PATH" ] && grep -qs '^ParsedResult: Success$' "$DUPLICATI__RESULTFILE"; then
        echo "======================================================" >> "$log_file"
        echo "=============== List of Changes: =====================" >> "$log_file"
        echo "======================================================" >> "$log_file"

        "$DUPLICATI_CLI_PATH" compare file://foo --dbpath=$DUPLICATI__dbpath --verbose >> "$log_file"

        echo -en '\n\n' >> "$log_file"
    fi
fi

if [[ -f "$DUPLICATI__log_file" ]]; then
    echo "======================================================" >> "$log_file"
    echo "=================== Log File:  =======================" >> "$log_file"
    echo "======================================================" >> "$log_file"
    cat "$DUPLICATI__log_file" >> "$log_file"

    echo -en '\n\n' >> "$log_file"
fi

if [[ -f "$DUPLICATI__backend_log_database" ]]; then
    echo "======================================================" >> "$log_file"
    echo "============= Backend Log Database:  =================" >> "$log_file"
    echo "======================================================" >> "$log_file"
    cat "$DUPLICATI__backend_log_database" >> "$log_file"
fi
