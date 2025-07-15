#! /usr/bin/env sh
# luatdd.sh
# A script for monitoring Lua files under TDD.
#set -e

luatdd_version=$(lua -lluatdd -e "print(luatdd.version)")
file_pattern="*.lua"
msg="luatdd version $luatdd_version: CTRL-C to quit"

match_test='_test.lua$'
all_tests=$(find -type f | grep $match_test | sort)

# Get count of test files.
test_count=0
for test in $all_tests
do
    test_count=$((test_count + 1))
done

attempt_count=1
pass_count=
fail_count=
msg_files=
msg_pass_files=
msg_fail_files=
while true
do
    printf "%s\n" "Attempt: $attempt_count"
    pass_count=0
    fail_count=0
    msg_files="files"
    msg_pass_files="files"
    msg_fail_files="files"
    for test in $all_tests
    do
        if lua "$test"
        then
            pass_count=$((pass_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
    done

    if [ $test_count -eq 1 ] ; then msg_files="file" ; fi
    if [ $pass_count -eq 1 ] ; then msg_pass_files="file" ; fi
    if [ $fail_count -eq 1 ] ; then msg_fail_files="file" ; fi
    printf "%d passing %s in %d test %s\n" \
           $pass_count $msg_pass_files $test_count $msg_files
    if [ $fail_count -gt 0 ]
    then
        printf "%d failing %s in %d test %s\n" \
               $fail_count $msg_fail_files $test_count $msg_files
    fi
    printf "%s\n\n" "$msg"
    watch -d -t -n 1 -p -g "ls -lR $file_pattern" > /dev/null
    attempt_count=$((attempt_count + 1))
done
