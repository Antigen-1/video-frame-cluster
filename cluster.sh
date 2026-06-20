#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE="$DIR/.cluster.cache.json"

detect_python() {
    if [ -x "$DIR/venv/bin/python3" ]; then echo "$DIR/venv/bin/python3"; return; fi
    if [ -n "$PYTHON" ] && command -v "$PYTHON" >/dev/null 2>&1; then command -v "$PYTHON"; return; fi
    for py in python3 python; do
        if command -v "$py" >/dev/null 2>&1; then command -v "$py"; return; fi
    done
    echo "Error: Python not found." >&2; exit 1
}

show_help() {
    cat <<EOF
Usage: $0 [options] <video> [num_clusters] [output_dir] [max_frames] [size]

  Hierarchical clustering (centroid-linkage, Euclidean distance) of video frames.
  Outputs the medoid frame (closest to centroid) of each cluster as a JPEG.

Arguments:
  video           Path to input video file (required)
  num_clusters    Number of clusters (default: 5)
  output_dir      Output directory for cluster images (default: cluster_output)
  max_frames      Max frames to extract (default: 50)
  size            Resize frames to size x size pixels (default: 16)

Options:
  -h, --help      Show this help message and exit
  -r, --recompile Force recompilation (ignore cache)

Examples:
  $0 my_video.mp4
  $0 -r my_video.mp4 10 my_output
  $0 my_video.mp4 10 my_output 100 32
EOF
    exit 0
}

[ "$1" = "-h" ] || [ "$1" = "--help" ] && show_help

FORCE=
if [ "$1" = "-r" ] || [ "$1" = "--recompile" ]; then
    FORCE=1
    shift
fi

[ -z "$1" ] && { echo "Error: video path is required. Use -h for help." >&2; exit 1; }

PY=$(detect_python)
CORE_DIR=$(racket -e '(display (path->string (build-path (collection-path "rkt-pythonize") "core")))')

export CLUSTER_VIDEO="$1"
export CLUSTER_N="${2:-5}"
export CLUSTER_OUTPUT="${3:-cluster_output}"
export CLUSTER_MAX_FRAMES="${4:-50}"
export CLUSTER_SIZE="${5:-16}"

# Use cache if source hasn't changed
if [ -z "$FORCE" ] && [ -f "$CACHE" ] && [ "$CACHE" -nt "$DIR/cluster.rkt" ]; then
    echo "(using cached compilation)" >&2
else
    racket -l- rkt-pythonize -o "$CACHE" -- "$DIR/cluster.rkt"
fi

PYTHONPATH="$CORE_DIR" "$PY" "$DIR/run_json.py" "$CACHE"
