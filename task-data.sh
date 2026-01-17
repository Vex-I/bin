#!/usr/bin/env bash

print_help() {
cat << EOF
Usage:
  task-data [OPTIONS]

Description:
  This is a bash script that is meant to be used with export-task. It takes in a stdin 
  of tasks and outputs a summary of the individual tasks within the given data.

EOF
}

case "$1" in
    -h|--help)
        print_help
        exit 0
        ;;
    *) shift ;;
esac

awk -F',' '
NR == 1 { next }  # skip header

{
    dur = $5

    task = $2

    cnt[task]++
    sum[task] += dur
    min[task] = (min[task] == "" || dur < min[task]) ? dur : min[task]
    max[task] = (max[task] == "" || dur > max[task]) ? dur : max[task]

    total += dur

}
END {
    printf "%36s %10s %36s\n", "", "WEEKLY REPORT", ""
    print "-----------------------------------------------------------------------------------------"
    printf "%-1s %-30s %10s %10s %10s %10s %10s %-1s\n",
    "|", "Task", "Sessions", "Total", "Avg", "Min", "Max", "|"
    print "-----------------------------------------------------------------------------------------"

    for (t in sum) {
        avg = sum[t] / cnt[t]
        f = 3600
        printf "%-1s %-30s %10s %10s %10s %10s %10s %-1s\n",
        "|", t, cnt[t],
        sum[t]/f, avg/f, min[t]/f, max[t]/f, "|"
    }

    print "-----------------------------------------------------------------------------------------"
printf "%-12s %8s %10.2f %-8s", "TOTAL", "", total/3600, "HOURS"
}
' | column -t -s $'\t'

