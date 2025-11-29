# Test suite for the 'line' CLI tool
# Exit codes: 0 = all tests pass, 1 = one or more tests failed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# From src/main.c:
OK=0
ERR_RUNTIME=1
ERR_ARGV=2
ERR_RANGE=3
ERR_TO_DO=4

# Helper function to run a test
run_test() {
    local test_name="$1"
    local expected_exit="$2"
    local expected_output="$3"
    shift 3
    local cmd=("$@")
    
    TESTS_RUN="$((TESTS_RUN + 1))"
    
    # Run the command and capture output and exit code
    set +e
    actual_output="$("${cmd[@]}" 2>&1)"
    actual_exit="$?"
    set -e
    
    # Check exit code
    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected exit code: $expected_exit"
        echo "  Actual exit code: $actual_exit"
        echo "  Command: ${cmd[*]}"
        echo "  Output: $actual_output"
        TESTS_FAILED="$((TESTS_FAILED + 1))"
        return 1
    fi
    
    # Check output (if expected output is provided)
    if [ -n "$expected_output" ]; then
        if [ "$actual_output" != "$expected_output" ]; then
            echo -e "${RED}✗ FAIL${NC}: $test_name"
            echo "  Expected output: '$expected_output'"
            echo "  Actual output: '$actual_output'"
            echo "  Command: ${cmd[*]}"
            TESTS_FAILED="$((TESTS_FAILED + 1))"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ PASS${NC}: $test_name"
    TESTS_PASSED="$((TESTS_PASSED + 1))"
    return 0
}

# Helper function to run a test that matches a pattern
run_test_pattern() {
    local test_name="$1"
    local expected_exit="$2"
    local pattern="$3"
    shift 3
    local cmd=("$@")
    
    TESTS_RUN="$((TESTS_RUN + 1))"
    
    # Run the command and capture output and exit code
    set +e
    actual_output="$("${cmd[@]}" 2>&1)"
    actual_exit="${?}"
    set -e
    
    # Check exit code
    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected exit code: $expected_exit"
        echo "  Actual exit code: $actual_exit"
        echo "  Command: ${cmd[*]}"
        TESTS_FAILED="$((TESTS_FAILED + 1))"
        return 1
    fi
    
    # Check output pattern
    if ! echo "$actual_output" | grep -q "$pattern"; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected pattern: '$pattern'"
        echo "  Actual output: '$actual_output'"
        echo "  Command: ${cmd[*]}"
        TESTS_FAILED="$((TESTS_FAILED + 1))"
        return 1
    fi
    
    echo -e "${GREEN}✓ PASS${NC}: $test_name"
    TESTS_PASSED="$((TESTS_PASSED + 1))"
    return 0
}

echo "======================================"
echo "Testing 'line' CLI tool"
echo "======================================"
echo

echo "=== Basic Functionality Tests ==="
echo

# Test reading from file
run_test "Read line 1 from file" "${OK}" "first line" ./line 1 test/input/test1.txt
run_test "Read line 3 from file" "${OK}" "third line" ./line 3 test/input/test1.txt
run_test "Read line 5 from file" "${OK}" "fifth line" ./line 5 test/input/test1.txt

# Test reading from stdin
run_test "Read line 1 from stdin" "${OK}" "first line" bash -c 'echo -e "first line\nsecond line\nthird line" | ./line 1'
run_test "Read line 2 from stdin" "${OK}" "second line" bash -c 'echo -e "first line\nsecond line\nthird line" | ./line 2'

echo
echo "=== Edge Cases ==="
echo

# Test line 0
run_test_pattern "Line 0 is a no-op" "${OK}" "" ./line 0 test/input/test1.txt

# Test single line file
run_test "Read only line from single-line file" "${OK}" "only one line" ./line 1 test/input/single.txt

# Test empty file
run_test_pattern "Empty file is a no-op" "${OK}" "" ./line 1 test/input/empty.txt

# Test line beyond EOF
run_test_pattern "Line beyond EOF in file" "${ERR_RANGE}" "" ./line 10 test/input/test1.txt
run_test_pattern "Line beyond EOF in stdin" "${ERR_RANGE}" "" bash -c 'echo -e "line1\nline2" | ./line 5'

# Test long lines (dynamic memory allocation)
run_test_pattern "Read very long line" "${OK}" "Lorem ipsum.*laborum\." ./line 1 test/input/long_lines.txt
run_test "Read short line after long line" "${OK}" "short line" ./line 2 test/input/long_lines.txt

run_test_pattern "Line number with leading space" "${OK}" "third line" ./line " 3" test/input/test1.txt

echo
echo "=== Error Handling Tests ==="
echo

# Test invalid arguments
run_test_pattern "No arguments" "${ERR_ARGV}" "usage:" ./line
run_test_pattern "Too many arguments" "${ERR_ARGV}" "usage:" ./line 1 file1.txt file2.txt

# Test invalid line numbers
run_test_pattern "Non-numeric line number" "${ERR_ARGV}" "" ./line abc test/input/test1.txt
run_test_pattern "Negative line number" "${ERR_TO_DO}" "TO-DO:" ./line -5 test/input/test1.txt
run_test_pattern "Empty line number" "${ERR_ARGV}" "" ./line "" test/input/test1.txt
run_test_pattern "Line number with trailing junk" "${ERR_ARGV}" "" ./line "3abc" test/input/test1.txt

# Test non-existent file
run_test_pattern "Non-existent file" 1 "No such file or directory" ./line 1 test/input/nonexistent.txt

# Test file permissions (create a file we can't read)
touch test/input/noperm.txt
chmod 000 test/input/noperm.txt
run_test_pattern "No permission to read file" 1 "Permission denied" ./line 1 test/input/noperm.txt || true
chmod 644 test/input/noperm.txt  # cleanup

echo
echo "=== Special Cases ==="
echo

# Test with grep output
run_test "Using with grep" "${OK}" "third line" bash -c 'grep "third" test/input/test1.txt | ./line 1'

# Test large line number
run_test_pattern "Very large line number" "${ERR_RANGE}" "" bash -c 'echo "test" | ./line 999999'

echo
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "Total tests: ${YELLOW}${TESTS_RUN}${NC}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
echo

if test "${TESTS_FAILED}" -eq 0; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi

