#! /usr/bin/env sh
# luatdd.sh
# A script for monitoring Lua files under TDD.
#set -e

file_pattern="*.lua"
driver="ex05-07_test.lua"
msg="CTRL-C to quit"

match_test='_test.lua$'

all_tests=$(find -type f |
                grep $match_test)

# for test in $all_tests ;
# do
#     echo $test
# done
            
test_count=1
while true
do
    printf "%s\n" "Testing: $test_count"
    for test in $all_tests ;
    do
        lua "$test"
    done
    echo "$msg"
    watch -d -t -n 1 -p -g "ls -lR $file_pattern" > /dev/null
    test_count=$((test_count + 1))
done

