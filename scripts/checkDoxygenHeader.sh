#!/bin/bash
# checkDoxygenHeader.sh
# Reads the first 30 lines of a given file and expects to find a proper doxygen header there.
# Returns 0 if no warnings/errors, 1 otherwise.

# a proper header looks like this:
# /**
#  * @file checkDoxygenHeader.sh
#  * @brief Validate that a C/C++ file starts with the expected Doxygen header.
#  *
#  * @version 1.0 // increment mayor if API or behavior changes (also bug fixes), increment minor if function was added
#  **/

set -euo pipefail

## @brief Print usage help.
## @return 0
usage() {
    cat <<'USAGE'
Usage: checkDoxygenHeader.sh [-v|--verbose] <file>

Checks whether <file> starts with a proper Doxygen header:
  - starts with /** (order of tags irrelevant)
  - contains: @file <actual-filename>, @brief, @date dd.mm.yyyy, @author
Exit codes: 0 = PASS, 1 = FAIL, 2 = bad invocation
USAGE
}

## @brief Escape regex metacharacters in a literal string.
## @param $1 literal string to escape
## @return prints escaped version to stdout
regex_escape() {
    # shellcheck disable=SC2001,SC2016
    # variables not expanding is intentional + Bash’s substitution can’t handle complex regex escaping safely
    sed 's/[.[\*^$()+?{}|]/\\&/g' <<<"$1"
}

## @brief Core check with optional verbose output.
## @param $1 path to file
## @param $2 "true" to enable verbose logging, "false" otherwise
## @return 0 on PASS, 1 on FAIL
check_header() {
    local file="$1"
    local verbose="$2"
    local filename
    filename=$(basename "$file")
    local filename_re
    filename_re=$(regex_escape "$filename")

    # Read first N lines, strip CR in case of CRLF
    local N=60
    local header
    header=$(head -n "$N" "$file" | sed 's/\r$//')

    # Tiny helper for conditional logging
    vlog() { if [[ "$verbose" == "true" ]]; then echo "$@"; fi; }

    local ok=true

    if [[ "$verbose" == "true" ]]; then
        echo "---- Checking: $file ----"
        echo "Header preview (first $N lines):"
        echo "--------------------------------"
        echo "$header"
        echo "--------------------------------"
    fi

    if [[ $header =~ ^[[:space:]]*/\*\* ]]; then
        vlog "[OK] starts with /**"
    else
        vlog "[FAIL] missing /** at start (allowing leading whitespace)"
        ok=false
    fi

    # @file must match the actual basename exactly
    local re_file="\\*+[[:space:]]*@file[[:space:]]+${filename_re}([[:space:]]|$)"
    if [[ $header =~ $re_file ]]; then
        vlog "[OK] @file $filename"
    else
        vlog "[FAIL] @file line missing or wrong filename (expected: $filename)"
        ok=false
    fi

    if [[ $header =~ \*+[[:space:]]*@brief ]]; then
        vlog "[OK] @brief found"
    else
        vlog "[FAIL] @brief missing"
        ok=false
    fi

    if [[ $header =~ \*/ ]]; then
        vlog "[OK] closing */ found"
    else
        vlog "[FAIL] closing */ missing (header may be longer than $N lines)"
        ok=false
    fi

    if $ok; then
        [[ "$verbose" == "true" ]] && echo "Result: PASS"
        return 0
    else
        [[ "$verbose" == "true" ]] && echo "Result: FAIL"
        return 1
    fi
}

# ---- CLI parsing ----
verbose="false"
file=""

while (($#)); do
    case "$1" in
        -v|--verbose) verbose="true"; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
        *) file="$1"; shift ;;
    esac
done

if [[ -z "${file:-}" ]]; then
    echo "Error: missing <file> argument." >&2
    usage
    exit 2
fi

check_header "$file" "$verbose"
