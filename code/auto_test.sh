#!/bin/bash

GROUND_TRUTH_DIR="$(pwd)/../project3/project3/correct_output33"
if [ ! -d "$GROUND_TRUTH_DIR" ]; then
    echo "Please setup correct_output/ in this directory"
    exit
fi
TEST_DIR="$(pwd)/output"

export VCS_LIC_EXPIRE_WARNING=0

for source_file in programs/*.{s,c}; do
    if [ "${source_file}" = "programs/crt.s" ]; then
        continue 
    fi
    program=$(echo "${source_file}" | cut -d '.' -f1 | cut -d '/' -f2) 
    
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo -e "Running \e[33m${program}\e[0m"
    make ${program}.out > /dev/null

    # System halt Test

    grep "System halted on WFI instruction" output/${program}.out > /dev/null
    if [ $? -eq 0 ]; then
        echo -e "halt test:      \e[32mPASS\e[0m"
    else
        echo -e "halt test:      \e[31mFAIL\e[0m"
    fi

    # Writeback output Test
    
    # compare the test output and ground truth output
    diff ${TEST_DIR}/${program}.wb ${GROUND_TRUTH_DIR}/${program}.wb > /dev/null
    if [ $? -eq 0 ]; then
        echo -e "writeback test: \e[32mPASS\e[0m"
    else
        echo -e "writeback test: \e[31mFAIL\e[0m"
    fi

    # Memory output Test

    # search for all lines start with "@@@"
    cat ${GROUND_TRUTH_DIR}/${program}.out | grep "@@@" > ground_truth_output.tmp
    cat ${TEST_DIR}/${program}.out | grep "@@@" > test_output.tmp

    # compare the memory outputs of test and ground truth
    # diff ground_truth_output.tmp test_output.tmp > /dev/null
    # if [ $? -eq 0 ]; then
    #     echo -e "memory test:    \e[32mPASS\e[0m"
    # else
    #     echo -e "memory test:    \e[31mFAIL\e[0m"
    # fi

done

rm *.tmp
    
echo "@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@@@@@END OF TEST@@@@@@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@"
