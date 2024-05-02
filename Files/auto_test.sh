#!/bin/bash

# GROUND_TRUTH_DIR=~/csee4824/4824-labs/lab4/project3_ground_truth
TEST_DIR=$(pwd)
# TEST_DIR=${GROUND_TRUTH_DIR}

export VCS_LIC_EXPIRE_WARNING=0

# if [ -d "${GROUND_TRUTH_DIR}/output" ]; then
#     echo "Ground Truth files exist"
# else
#     echo "Generating Ground Truth files"
#     ./generate_ground_truth.sh
# fi

# echo "Comparing ground truth outputs to new processor"

# cd ${TEST_DIR}
# source setup-paths.sh


for source_file in programs/*.{s,c}; do
    if [ "${source_file}" = "programs/crt.s" ]; then
        continue 
    fi
    program=$(echo "${source_file}" | cut -d '.' -f1 | cut -d '/' -f2) 
    
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo -e "Running \e[33m${program}\e[0m"
    make ${program}.out > /dev/null

    # Writeback output Test
    
    # # compare the test output and ground truth output
    # diff ${TEST_DIR}/output/${program}.wb ${GROUND_TRUTH_DIR}/output/${program}.wb > /dev/null
    # if [ $? -eq 0 ]; then
    #     echo -e "writeback test: \e[32mPASS\e[0m"
    # else
    #     echo -e "writeback test: \e[31mFAIL\e[0m"
    # fi

    # # Memory output Test

    # # search for all lines start with "@@@"
    # cat ${GROUND_TRUTH_DIR}/output/${program}.out | grep "@@@" > ground_truth_output.tmp
    # cat ${TEST_DIR}/output/${program}.out | grep "@@@" > test_output.tmp

    # # compare the memory outputs of test and ground truth
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
