#!/usr/bin/env bash
cd "$(dirname $0)";

yellow='\033[33m'
green='\033[32m'
clear='\033[m'

for input in src/*.coffee
do
    output="$(sed 's/\.coffee$/\.js/' <<< "${input:4}")"

    echo -e "${yellow}>${clear} ${green}${input}${clear} to ${green}${output}${clear}";
    ./node_modules/.bin/coffee -to "${output}" "${input}"
done
