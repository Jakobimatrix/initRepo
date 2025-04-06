#!/bin/bash

# Default values
corpus="corpus"
jobs=4
minimize=0

print_help() {
    echo "Usage: $0 <executable> [-c corpus_dir] [-j jobs] [-h]"
    echo ""
    echo "Arguments:"
    echo "  <executable>     Path to the fuzzer executable (required)"
    echo "  -c <corpus_dir>  Directory for corpus input/output (default: ./corpus)"
    echo "  -j <jobs>        Number of parallel jobs (default: 4)"
    echo "  -m               Minimize corpus before fuzzing"
    echo "  -h               Show this help message"
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    print_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--corpus)
            corpus="$2"
            shift 2
            ;;
        -j|--jobs)
            jobs="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -m|--minimize)
            minimize=1
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            print_help
            exit 1
            ;;
        *)
            if [[ -z "$executable" ]]; then
                executable="$1"
                shift
            else
                echo "Unexpected argument: $1"
                print_help
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$executable" ]]; then
    echo "Error: No executable specified."
    print_help
    exit 1
fi

if [[ ! -x "$executable" ]]; then
    echo "Error: '$executable' is not executable."
    exit 1
fi

mkdir -p "$corpus"

if [[ "$minimize" -eq 1 ]]; then
    echo "Minimizing corpus..."
    tmp_corpus=$(mktemp -d)
    "./$executable" "$tmp_corpus" \
        -merge=1 "$corpus"
    rm -r "$corpus"
    mv "$tmp_corpus" "$corpus"
    echo "Corpus minimized."
    echo ""
fi

echo "Running fuzzer:"
echo "  Executable:       $executable"
echo "  Corpus directory: $corpus"
echo "  Jobs:             $jobs"
echo "  Minimize first:   $minimize"
echo ""

"./$executable" "$corpus" \
    -print_final_stats=1 \
    -print_corpus_stats=1 \
    -create_missing_dirs=1 \
    -fork="$jobs" \
    -seed_inputs="$corpus" \
    -max_len="$corpus" \
    -keep_going=1 \
    -ignore_crashes=1
