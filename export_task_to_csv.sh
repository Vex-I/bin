#!/usr/bin/env bash


set -euo pipefail
DEFAULT_DB_PATH="$HOME/hours.db"
DEFAULT_OUT_PATH="$HOME"
DEFAULT_OUT_NAME="task_log.csv"
EXPORT_TO_STDOUT=false
DEFAULT_RANGE='all'

DB_PATH=$DEFAULT_DB_PATH          # e.g. /path/to/tasks.db
OUT_DIR=$DEFAULT_OUT_PATH          # e.g. /path/to/output
OUT_FILE=$DEFAULT_OUT_NAME         # output file name
USE_RANGE=$DEFAULT_RANGE           # 'week', 'today', 'all'


print_help() {
    cat <<EOF
Usage:
  export-task [OPTIONS]

Description:
  This is a bash script made to work with dhth/hours, a CLI that tracks time allocation. This script
  is made to output the hours.db file to a proccessed, csv format, which makes it easier to proccess 
  the data.

Options:
  -h, --help                Show this help message and exit
  --db DB_PATH              Specify the DB Path. Default: $DEFAULT_DB_PATH
  --out-dir PATH            Specify the output directory. Default: $DEFAULT_OUT_PATH
  --out-file NAME           Specify the output file name. Default: $DEFAULT_OUT_NAME
  --stdout                  Output as stdout instead of CSV
  -w [week | today | all]   Restrict the data to the given range.

Example:
  export-task --db ~/data/tasks.db --out-dir ~/exports
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        --db)
            DB_PATH="$2"
            shift 2
            ;;
        --out-dir)
            OUT_DIR="$2"
            shift 2
            ;;
        --out-file)
            OUT_FILE="$2"
            shift 2
            ;;
        --stdout)
            EXPORT_TO_STDOUT=true
            shift
            ;;
        -w)
            USE_RANGE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo
            print_help
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ ! -f "$DB_PATH" ]]; then
    echo "No .db file in $DB_PATH"
    exit 1
fi

if $EXPORT_TO_STDOUT; then
    OUT_PATH="/dev/stdout"
else
    mkdir -p "$OUT_DIR"
    OUT_PATH="$OUT_DIR/$OUT_FILE"
fi

case "$USE_RANGE" in 
    week)
        sqlite3 -header -csv "$DB_PATH" "
        SELECT
        date(
            datetime(
                substr(t.begin_ts, 1, 10) || ' ' ||
                    replace(substr(t.begin_ts, 12, 8), '-', ':')
                , 'localtime')
                ) AS day,
                m.summary AS TASK_NAME,
                datetime(substr(t.begin_ts, 1, 10) || ' ' || replace(substr(t.begin_ts, 12, 8), '-', ':'), 'localtime')
                AS BEGIN_TIME,
                datetime(substr(t.end_ts, 1, 10) || ' ' || replace(substr(t.end_ts, 12, 8), '-', ':'), 'localtime')
                AS END_TIME,
                t.secs_spent AS SECONDS_SPENT
                FROM task_log t
                JOIN task m ON m.id = t.task_id
                WHERE  
                BEGIN_TIME >= datetime(
                    'now',
                    'localtime',
                    '-' || ((strftime('%w', 'now', 'localtime') + 6) % 7) || ' days',
                    'start of day'
                )
                    AND BEGIN_TIME <= datetime('now', 'localtime')
                ORDER BY day, t.begin_ts;
                " > "$OUT_PATH"

        ;;
    today)
        sqlite3 -header -csv "$DB_PATH" "
        SELECT
        date(
            datetime(
                substr(t.begin_ts, 1, 10) || ' ' ||
                    replace(substr(t.begin_ts, 12, 8), '-', ':')
                , 'localtime')
                ) AS day,
                m.summary AS TASK_NAME,
                datetime(substr(t.begin_ts, 1, 10) || ' ' || replace(substr(t.begin_ts, 12, 8), '-', ':'), 'localtime')
                AS BEGIN_TIME,
                datetime(substr(t.end_ts, 1, 10) || ' ' || replace(substr(t.end_ts, 12, 8), '-', ':'), 'localtime')
                AS END_TIME,
                t.secs_spent AS SECONDS_SPENT
                FROM task_log t
                JOIN task m ON m.id = t.task_id
                WHERE day == date(datetime('now', 'localtime'))
                ORDER BY day, t.begin_ts;
                " > "$OUT_PATH"
        ;;
    all)
        sqlite3 -header -csv "$DB_PATH" "
        SELECT
        date(
            datetime(
                substr(t.begin_ts, 1, 10) || ' ' ||
                    replace(substr(t.begin_ts, 12, 8), '-', ':')
                , 'localtime')
                ) AS day,
                m.summary AS TASK_NAME,
                datetime(substr(t.begin_ts, 1, 10) || ' ' || replace(substr(t.begin_ts, 12, 8), '-', ':'), 'localtime')
                AS BEGIN_TIME,
                datetime(substr(t.end_ts, 1, 10) || ' ' || replace(substr(t.end_ts, 12, 8), '-', ':'), 'localtime')
                AS END_TIME,
                t.secs_spent AS SECONDS_SPENT
                FROM task_log t
                JOIN task m ON m.id = t.task_id
                ORDER BY day, t.begin_ts;
                " > "$OUT_PATH"
esac

if ! $EXPORT_TO_STDOUT; then
    echo "CSV exported to: $OUT_PATH"
fi

