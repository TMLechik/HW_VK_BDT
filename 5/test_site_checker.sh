#!/bin/bash

echo "Starting Site Checker Test Suite in GitLab CI"

FAILED_TESTS=0
TESTS_RUN=0

run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="${3:-0}"

    TESTS_RUN=$((TESTS_RUN+1))

    echo "--- $test_name ---"

    eval "$command"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if [ $exit_code -eq "$expected_exit" ]; then
            echo "✅ PASS: $test_name"
            return 0
        else
            echo "❌ FAIL: $test_name - Wrong exit code (expected $expected_exit, got $exit_code)"
            FAILED_TESTS=$((FAILED_TESTS+1))
            return 1
        fi
    else
        if [ $exit_code -eq "$expected_exit" ]; then
            echo "✅ PASS: $test_name"
            return 0
        else
            echo "❌ FAIL: $test_name - Command failed with exit code $exit_code"
            FAILED_TESTS=$((FAILED_TESTS+1))
            return 1
        fi
    fi
}

echo "=== Basic Functionality Tests ==="
run_test "Help command" "./site_checker.sh --help" 0
echo -e "\n"
run_test "Missing URL" "./site_checker.sh" 1
echo -e "\n"
run_test "Invalid output format" "./site_checker.sh --output=invalid http://example.com" 1

echo -e "\n"
echo -e "\n"

echo "=== HTTP Status Tests ==="
run_test "HTTP 200" "./site_checker.sh https://httpbin.org/status/200" 0
echo -e "\n"
run_test "HTTP 404" "./site_checker.sh https://httpbin.org/status/404" 0 
echo -e "\n"
run_test "HTTP 500" "./site_checker.sh https://httpbin.org/status/500" 0

echo -e "\n"

echo "=== Output Format Tests ==="
run_test "Text output" "./site_checker.sh --output=text https://httpbin.org/status/200" 0


echo
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $((TESTS_RUN - FAILED_TESTS))"
echo "Tests failed: $FAILED_TESTS"

if [ $FAILED_TESTS -gt 0 ]; then
    echo "❌ TEST SUITE FAILED"
    exit 1
else
    echo "✅ ALL TESTS PASSED"
    exit 0
fi