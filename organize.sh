#!/usr/bin/env bash
set -euo pipefail

DEFAULT_DEPTH = 2
DEFAULT_FILTER = (".pdf", ".doc", ".docx", ".png", ".jpg", ".jpeg")

print_help() {
    cat <<EOF
Usage:
  $0 [OPTIONS]

Description:
  A simple bash script that organizes a document directory recursively, up to a certain depth.

Options:
  -h, --help        Show this help message and exit
  -r LEVEL          Set the recursion depth. Default: $DEFAULT_DEPTH
  -f [FILTER]       The documents type to be organized.
Example:
    
EOF
}
