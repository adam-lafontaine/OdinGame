#!/bin/bash

# chmod +x ./build_gen.sh

cmd=${1:-build}

CYAN='\033[0;36m'
NC='\033[0m'


defines=(
    "-define:EMBED=true"
    "-define:BINARY=true"
    )



echo "→ odin $cmd . Gernate Assets"
echo "──────────────────────────────────────────"

output=$(odin $cmd . ${defines[*]})
exit_code=$?

echo "$output"

echo "──────────────────────────────────────────"

if [ $exit_code -eq 0 ]; then
    echo -e "\x1b[32m✓ Build succeeded\x1b[0m"
else
    echo -e "\x1b[31m✗ Build failed\x1b[0m"
fi

exit $exit_code