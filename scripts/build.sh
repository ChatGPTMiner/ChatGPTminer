#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cmake -S "$project_dir" -B "$project_dir/build" -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build "$project_dir/build" --parallel "$(nproc)"
ctest --test-dir "$project_dir/build" --output-on-failure
mkdir -p "$project_dir/out"
cmake --install "$project_dir/build" --prefix "$project_dir/out"

