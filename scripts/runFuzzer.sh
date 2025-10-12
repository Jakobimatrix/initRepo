#!/bin/bash

# Default values
corpus="corpus"
seeds="seeds"
jobs=4
minimize=0
max_len=""

print_help() {
    echo "Usage: $0 <executable> [-c corpus_dir] [-j jobs] [-m] [--max_len N] [-h]"
    echo ""
    echo "Arguments:"
    echo "  <executable>     Path to the fuzzer executable (required)"
    echo "  -c <corpus_dir>  Directory for corpus input/output (default: ./corpus)"
    echo "  -j <jobs>        Number of parallel jobs (default: 4)"
    echo "  -m               Minimize corpus before fuzzing"
    echo "  --max_len <N>    Maximum input length for fuzzing"
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
        -m|--minimize)
            minimize=1
            shift
            ;;
        --max_len)
            max_len="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
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

# Convert to absolute path if not already
if [[ "$executable" != /* ]]; then
    executable="$(realpath "$executable")"
fi

if ! nm "$executable" 2>/dev/null | grep -q "LLVMFuzzerTestOneInput"; then
    echo "Error: This executable does not appear to be a libFuzzer binary. You need to use the release build:  './initRepo/scripts/build.sh --compiler clang -r -f'"
    echo "If you want to debug the fuzzer (for example because it crashed) run '$executable <path to crash binary>' then attatch to your debugger and press enter."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
cd ../../

mkdir -p "fuzz"
cd fuzz  || exit 1

mkdir -p "$corpus"
mkdir -p "$seeds"
seeds="$(realpath "$seeds")"
corpus="$(realpath "$corpus")"

if [[ "$minimize" -eq 1 ]]; then
    echo "Minimizing corpus..."
    tmp_corpus=$(mktemp -d)
    "$executable" "$tmp_corpus" -merge=1 "$corpus"
    rm -r "$corpus"
    mv "$tmp_corpus" "$corpus"
    echo "Corpus minimized."
    echo ""
fi

echo "Running fuzzer:"
echo "  Executable:       $executable"
echo "  Corpus directory: $corpus"
echo "  Seed directory:   $seeds"
echo "  Jobs:             $jobs"
echo "  Minimize first:   $minimize"
if [[ -n "$max_len" ]]; then
    echo "  Max input length: $max_len"
fi
echo ""

# Build command
cmd=(
  "$executable" "$corpus"
  "-print_final_stats=1"
  "-print_corpus_stats=1"
  "-create_missing_dirs=1"
  "-fork=$jobs"
  "-seed_inputs=$seeds"
  "-keep_going=1"
  "-ignore_crashes=1"
)

# Add max_len if specified
if [[ -n "$max_len" ]]; then
    cmd+=("-max_len=$max_len")
fi

# Run fuzzer
"${cmd[@]}"
