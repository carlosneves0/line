# line

A simple, fast CLI tool to extract a specific line from a file or stdin.

## Features

- ✅ Extract lines from files or stdin
- ✅ 1-based line numbering (line 1 is the first line)
- ✅ Simple character-by-character reading - no dynamic memory allocation
- ✅ Comprehensive error handling with specific exit codes
- ✅ Memory-safe and efficient
- ✅ Fast and lightweight

## Installation

```bash
make
sudo make install
```

By default, this installs to `/usr/local/bin`. To install to a different location:

```bash
make install PREFIX=/custom/path
```

## Usage

```bash
# Extract line 3 from a file
line 3 file.txt

# Extract line 1 from stdin
cat file.txt | line 1

# Use with grep to get the first match
grep "pattern" file.txt | line 1

# Extract line 5 from command output
ls -la | line 5
```

## Examples

```bash
# Get the 10th line of a file
$ line 10 /etc/passwd
_cvmsroot:*:212:212:CVMS Root:/var/empty:/usr/bin/false

# Get the first match from grep
$ grep "main" main.c | line 1
int main(int argc, const char **argv)

# Extract a specific line from piped input
$ echo -e "apple\nbanana\ncherry" | line 2
banana
```

## Error Handling

The tool uses specific exit codes and provides helpful error messages:

**Exit Codes:**
- `0` (OK): Success
- `1` (ERR_RUNTIME): Runtime error (file not found, permission denied, etc.)
- `2` (ERR_ARGV): Invalid arguments
- `3` (ERR_RANGE): Line number out of range
- `4` (ERR_TO_DO): Feature not yet implemented

**Examples:**

```bash
# Invalid line number
$ line abc file.txt
# Exit code: 2

# Line doesn't exist
$ line 100 file.txt
# Exit code: 3

# File doesn't exist
$ line 1 missing.txt
line: missing.txt: No such file or directory
# Exit code: 1

# Line 0 is a no-op (returns success with no output)
$ line 0 file.txt
# Exit code: 0

# Negative line numbers (reverse indexing - not yet implemented)
$ line -1 file.txt
TO-DO: "reversed" line
# Exit code: 4
```

## Building

### Requirements

- GCC or compatible C compiler
- Make
- Standard C library

### Build Commands

```bash
# Build the release version
make

# Build debug version with symbols
make debug

# Run tests
make test

# Clean build artifacts
make clean

# Check for memory leaks (requires valgrind)
make valgrind
```

## Development

### Running Tests

The project includes a comprehensive test suite covering:

- Basic functionality (reading from files and stdin)
- Edge cases (empty files, single-line files, long lines, line 0)
- Error handling (invalid inputs, missing files, permission errors)
- Integration with other tools (grep, pipes)
- Exit code validation

```bash
make test
```

### Project Structure

```
.
├── src/
│   ├── main.c      # Main source code
│   └── int64.h     # Integer parsing utilities
├── test/
│   ├── main.bash   # Test suite
│   └── input/      # Test input files
├── makefile        # Build configuration
├── README.md       # This file
└── LICENSE         # License information
```

## Technical Details

- **Language**: C (C99 standard)
- **Line numbering**: 1-based (line 1 is the first line)
- **Memory allocation**: No dynamic allocation - character-by-character reading
- **Maximum line number**: 2^63-1 (int64_t)
- **Optimization**: Built with `-O3` for maximum performance
- **Line length**: Unlimited (no buffer constraints)

## Performance

The tool uses character-by-character reading with no dynamic memory allocation, making it extremely simple, fast, and memory-efficient. It can handle lines of any length without buffer constraints or allocation overhead.

## License

See LICENSE file for details.

## Contributing

Feel free to submit issues or pull requests!

## Author

Built with ❤️ for simple, reliable line extraction.

