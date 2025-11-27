#!/usr/bin/env bash

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

# Create test output directory
mkdir -p tmp

# Helper function to run a test
run_test() {
    local test_name="$1"
    local expected_exit="$2"
    local expected_output="$3"
    shift 3
    local cmd=("$@")
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Run the command and capture output and exit code
    set +e
    actual_output=$("${cmd[@]}" 2>&1)
    actual_exit=$?
    set -e
    
    # Check exit code
    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected exit code: $expected_exit"
        echo "  Actual exit code: $actual_exit"
        echo "  Command: ${cmd[*]}"
        echo "  Output: $actual_output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    # Check output (if expected output is provided)
    if [ -n "$expected_output" ]; then
        if [ "$actual_output" != "$expected_output" ]; then
            echo -e "${RED}✗ FAIL${NC}: $test_name"
            echo "  Expected output: '$expected_output'"
            echo "  Actual output: '$actual_output'"
            echo "  Command: ${cmd[*]}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ PASS${NC}: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

# Helper function to run a test that matches a pattern
run_test_pattern() {
    local test_name="$1"
    local expected_exit="$2"
    local pattern="$3"
    shift 3
    local cmd=("$@")
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Run the command and capture output and exit code
    set +e
    actual_output=$("${cmd[@]}" 2>&1)
    actual_exit=$?
    set -e
    
    # Check exit code
    if [ "$actual_exit" -ne "$expected_exit" ]; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected exit code: $expected_exit"
        echo "  Actual exit code: $actual_exit"
        echo "  Command: ${cmd[*]}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    # Check output pattern
    if ! echo "$actual_output" | grep -q "$pattern"; then
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected pattern: '$pattern'"
        echo "  Actual output: '$actual_output'"
        echo "  Command: ${cmd[*]}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    echo -e "${GREEN}✓ PASS${NC}: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

echo "======================================"
echo "Testing 'line' CLI tool"
echo "======================================"
echo

# Create test files
cat > tmp/test1.txt << 'EOF'
first line
second line
third line
fourth line
fifth line
EOF

cat > tmp/empty.txt << 'EOF'
EOF

printf > tmp/single.txt 'only one line'

cat > tmp/long_lines.txt << 'EOF'
This is a very long line that exceeds the initial buffer size to test dynamic memory allocation. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
short line
EOF

echo "=== Basic Functionality Tests ==="
echo

# Test reading from file
run_test "Read line 1 from file" 0 "first line" ./line 1 tmp/test1.txt
run_test "Read line 3 from file" 0 "third line" ./line 3 tmp/test1.txt
run_test "Read line 5 from file" 0 "fifth line" ./line 5 tmp/test1.txt

# Test reading from stdin
run_test "Read line 1 from stdin" 0 "first line" bash -c 'echo -e "first line\nsecond line\nthird line" | ./line 1'
run_test "Read line 2 from stdin" 0 "second line" bash -c 'echo -e "first line\nsecond line\nthird line" | ./line 2'

echo
echo "=== Edge Cases ==="
echo

# Test line 0
run_test_pattern "Line 0 should error" 1 "line cannot be zero" ./line 0 tmp/test1.txt

# Test single line file
run_test "Read only line from single-line file" 0 "only one line" ./line 1 tmp/single.txt

# Test empty file
run_test_pattern "Read from empty file" 1 "not found.*has 0 line" ./line 1 tmp/empty.txt

# Test line beyond EOF
run_test_pattern "Line beyond EOF in file" 1 "not found.*has 5 lines" ./line 10 tmp/test1.txt
run_test_pattern "Line beyond EOF in stdin" 1 "not found.*has 2 lines" bash -c 'echo -e "line1\nline2" | ./line 5'

# Test long lines (dynamic memory allocation)
run_test_pattern "Read very long line" 0 "This is a very long line.*laborum\." ./line 1 tmp/long_lines.txt
run_test "Read short line after long line" 0 "short line" ./line 2 tmp/long_lines.txt

echo
echo "=== Error Handling Tests ==="
echo

# Test invalid arguments
run_test_pattern "No arguments" 1 "Usage:" ./line
run_test_pattern "Too many arguments" 1 "Usage:" ./line 1 file1.txt file2.txt

# Test invalid line numbers
run_test_pattern "Non-numeric line number" 1 "not a valid line number" ./line abc tmp/test1.txt
run_test_pattern "Negative line number" 1 "not a valid line number" ./line -5 tmp/test1.txt
run_test_pattern "Line number with leading space" 1 "cannot be empty or start with whitespace" ./line " 3" tmp/test1.txt
run_test_pattern "Empty line number" 1 "cannot be empty" ./line "" tmp/test1.txt
run_test_pattern "Line number with trailing junk" 1 "not a valid line number" ./line "3abc" tmp/test1.txt

# Test non-existent file
run_test_pattern "Non-existent file" 1 "cannot open" ./line 1 tmp/nonexistent.txt

# Test file permissions (create a file we can't read)
touch tmp/noperm.txt
chmod 000 tmp/noperm.txt
run_test_pattern "No permission to read file" 1 "cannot open.*Permission denied" ./line 1 tmp/noperm.txt || true
chmod 644 tmp/noperm.txt  # cleanup

echo
echo "=== Special Cases ==="
echo

# Test with grep output
run_test "Using with grep" 0 "third line" bash -c 'grep "third" tmp/test1.txt | ./line 1'

# Test large line number
run_test_pattern "Very large line number" 1 "not found" bash -c 'echo "test" | ./line 999999'

echo
echo "======================================"
echo "Test Summary"
echo "======================================"
echo -e "Total tests: ${YELLOW}$TESTS_RUN${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi

