#!/bin/bash

frame_quote() {
    MAX_WIDTH=80

    if [ -t 0 ]; then
        # No stdin, use argument
        input="$*"
    else
        input=$(cat)
    fi

    lines=()
    while IFS= read -r line; do
        while [ ${#line} -gt $MAX_WIDTH ]; do
            lines+=("${line:0:$MAX_WIDTH}")
            line="${line:$MAX_WIDTH}"
        done
        lines+=("$line")
    done <<< "$input"

    max_len=0
    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done

    printf '+'
    printf -- '-%.0s' $(seq 1 $((max_len + 2)))
    printf '+\n'

    for line in "${lines[@]}"; do
        printf '| %s' "$line"
        printf -- ' %.0s' $(seq 1 $((max_len - ${#line} + 1)))
        printf '|\n'
    done

    printf '+'
    printf -- '-%.0s' $(seq 1 $((max_len + 2)))
    printf '+\n'
}

frame_quote "$@"

