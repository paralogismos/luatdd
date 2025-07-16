#! /usr/bin/env sh
# luatdd.sh
# A script for monitoring Lua files under TDD.
luatdd_version=$(lua -lluatdd -e "print(luatdd.version)")
msg="luatdd $luatdd_version: press CTRL-C to quit"

# Trap ^Z and ^\ if `trap` is available.
# if type trap > /dev/null ; then
#     trap "run_tests" TSTP  # SIGTSTP
#     trap "quit" QUIT    # SIGQUIT
#     msg="press CTRL-Z to force test, CTRL-\ to quit"
# fi

# quit() {
#     stty echo
#     exit 0
# }

file_pattern="*.lua"
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

# This is run in the loop when watched files change,
# or when the user signals ^Z for force testing.
run_tests() {
    for test in $all_tests
    do
        if lua "$test"
        then
            pass_count=$((pass_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
    done
    attempt_count=$((attempt_count + 1))
}

while true
do
    pass_count=0
    fail_count=0
    msg_files="files"
    msg_pass_files="files"
    msg_fail_files="files"

    printf "\n%s\n" "Attempt: $attempt_count"
    run_tests

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

    printf "\n%s\n" "$msg"
    watch -d -t -n 1 -p -g "ls -lR --full-time $file_pattern" > /dev/null
done
