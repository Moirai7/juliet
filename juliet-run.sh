#!/bin/bash

# the first parameter of this script is either an integer or the string "all".
# if given a number, it will target a subdirectory *in its directory* that
# contains test cases correspding to that CWE number.  if given "all", it will
# target all subdirectories *in its directory* containing CWE test cases.

# the second parameter is optional and specifies a timeout duration. the
# default value is .01 seconds.

# this script will run all good and bad tests in the targeted subdirectories
# and write the names of the tests and their return codes into the files
# "good.run" and "bad.run", both located in the subdirectories. all tests are
# run with a timeout so that tests requiring input terminate quickly with
# return code 124.

ulimit -c 0 # TODO no core dumps for now

SCRIPT_DIR=$(dirname $(realpath "$0"))
TIMEOUT=".01s"

if [ $# -lt 1 ]
then
  echo "need to specify target - see source comments for help"
  exit
fi

TARGET="$1"

if [ $# -ge 2 ]
then
  CASES="$2"
fi

if [ $# -ge 3 ]
then
  TIMEOUT="$3"
fi

# parameter 1: the CWE directory corresponding to the tests
# parameter 2: the type of tests to run (should be "good" or "bad")
run_tests()
{
  local CWE_DIRECTORY="$1"
  local TEST_TYPE="$2"
  local TESTCASES="$3"
  local TYPE_PATH="${CWE_DIRECTORY}/${TEST_TYPE}"

  local PREV_CWD=$(pwd)
  cd "${CWE_DIRECTORY}" # change directory in case of test-produced output files

  echo "========== STARTING TEST ${TYPE_PATH} $(date) ==========" >> "${TYPE_PATH}.run"
  ALLCASES=($( ls ${TYPE_PATH} ))
  for i in $(echo $TESTCASES | tr "," "\n"); do
    TESTCASE="${ALLCASES[i-1]}"
    local TESTCASE_PATH="${TYPE_PATH}/${TESTCASE}"
    timeout "${TIMEOUT}" "${TESTCASE_PATH}" 0 # timeout requires an argument after the command
    #echo "${TESTCASE_PATH} $?" >> "${TYPE_PATH}.run"
    if [ $? -ne 0 ]; then
	    echo "timed out"
	    exit 1
    fi
  done

  cd "${PREV_CWD}"
  echo "successful"
  exit 0
}

if [ "${TARGET}" = "all" ]
then
  for DIRECTORY in $(ls -1 "${SCRIPT_DIR}"); do
    if [ $(expr "${DIRECTORY}" : "^CWE[0-9][0-9]*$") -ne 0 ] # make sure this is a CWE directory
    then
      FULL_PATH="${SCRIPT_DIR}/${DIRECTORY}"
      #run_tests "${FULL_PATH}" "good" "${CASES}"
      run_tests "${FULL_PATH}" "bad" "${CASES}"
    fi
  done
elif [ -d "${SCRIPT_DIR}/CWE${TARGET}" ]
then
  FULL_PATH="${SCRIPT_DIR}/CWE${TARGET}"
  #run_tests "${FULL_PATH}" "good" "${CASES}"
  run_tests "${FULL_PATH}" "bad" "${CASES}"
else
  echo "specified target did not correspond to a built CWE testcase directory - see source comments for help"
  exit
fi
