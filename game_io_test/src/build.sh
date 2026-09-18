#!/bin/bash
# 

cmd=${1:-build}

out_dir="../build"

out_exe="${out_dir}/io_test"

asset_bin="../gen/out/io_test_data.bin"


defines=(
    "-define:ASSETS_BINARY=false"
    )

# odin help build
flags=(
    "-debug"
    "-out:${out_exe}"
)

cmd_str="odin ${cmd} . ${defines[*]} ${flags[*]}"

echo "Odin IO Test"
echo $cmd_str
echo "──────────────────────────────────────────"

mkdir -p $out_dir
copy_bin=$(cp $asset_bin $out_dir)

output=$(odin $cmd . ${defines[*]} ${flags[*]})
exit_code=$?

echo "──────────────────────────────────────────"

if [ $exit_code -eq 0 ]; then
    echo -e "\x1b[32m✓ Build succeeded\x1b[0m"
else
    echo -e "\x1b[31m✗ Build failed\x1b[0m"
fi

exit $exit_code