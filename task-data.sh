#!/usr/bin/env bash

print_help() {
cat << EOF
Usage:
  task-data [OPTIONS]

Description:
  This is a bash script that is meant to be used with export-task. It takes in a stdin 
  of tasks and outputs a summary of the individual tasks within the given data.
Options: 
  -t [TELE-ID] [BOT-ID]     Create a POST request to a telegram bot with the given ID 
                            to the user with the given id in a table format.

EOF
}


case "$1" in
    -h|--help)
        print_help
        exit 0
        ;;
    -t) 
        QUOTE=$(curl -s https://zenquotes.io/api/random | jq -r ".[].q")
        TARGET_ID=$2
        BOT_ID=$3
        OUTPUT=$(awk -F',' -v quote="$QUOTE" ' 
        NR == 1 { next }  # skip header

        {
            dur = $5

            task = $2
            gsub(/"/, "", task)

            cnt[task]++
            sum[task] += dur
            min[task] = (min[task] == "" || dur < min[task]) ? dur : min[task]
            max[task] = (max[task] == "" || dur > max[task]) ? dur : max[task]
            minDate = (minDate == "" || $1 < minDate) ? $1 : minDate
            maxDate = (maxDate == "" || $1 > maxDate) ? $1 : maxDate

            total += dur

        }
    END {
        printf "Report from %s to %s\n\n", minDate, maxDate
        for (t in sum) {
            avg = sum[t] / cnt[t]
            f = 3600
            printf "*%-25s* \n Sessions: %5.2f \n Total: %5.2fh \n Avg: %5.2fh \n Min: %5.2fh \n Max: %5.2fh \n \n",
            t, cnt[t], sum[t]/f, avg/f, min[t]/f, max[t]/f
        }

        printf "%-6s %4s %5.2f %-4s\n\n", "TOTAL", "", total/3600, "HOURS"

        printf "%s%s", ">", quote
    }')

        ESCAPED_OUTPUT=${OUTPUT//[-.]/\\\\&}
        echo $QUOTE

        curl --silent -H "Content-Type: application/json" \
            -d "{
                \"chat_id\": \"$TARGET_ID\",
                \"text\": \"$ESCAPED_OUTPUT\",
                \"parse_mode\": \"MarkdownV2\"
            }" \
                -X POST \
                "https://api.telegram.org/bot${BOT_ID}/sendMessage"
        ;;
    *) 

        awk -F',' '
        NR == 1 { next }  # skip header

        {
            dur = $5

            task = $2
            gsub(/"/, "", task)

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
shift ;;
esac

