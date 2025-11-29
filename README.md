# line

A simple, fast CLI tool to extract a specific line from a file or stdin.

## Features

- ✅ Extract lines from files or stdin
- ✅ 1-based line numbering (line 1 is the first line)
- ✅ Dynamic memory allocation - no line length limits
- ✅ Comprehensive error handling and validation
- ✅ Memory-safe with no leaks
- ✅ Fast and efficient

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

The tool provides helpful error messages:

```bash
# Invalid line number
$ line abc file.txt
Error: 'abc' is not a valid line number

# Line doesn't exist
$ line 100 file.txt
Error: line 100 not found in 'file.txt' (file has 10 lines)

# File doesn't exist
$ line 1 missing.txt
Error: cannot open 'missing.txt': No such file or directory

# Line 0 is invalid (1-based numbering)
$ line 0 file.txt
Error: line cannot be zero
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
make memcheck
```

## Development

### Running Tests

The project includes a comprehensive test suite with 23 tests covering:

- Basic functionality (reading from files and stdin)
- Edge cases (empty files, single-line files, long lines)
- Error handling (invalid inputs, missing files, permission errors)
- Integration with other tools (grep, pipes)

```bash
make test
```

### Project Structure

```
.
├── main.c          # Main source code
├── makefile        # Build configuration
├── test.sh         # Test suite
├── README.md       # This file
└── LICENSE         # License information
```

## Technical Details

- **Language**: C (C99 standard)
- **Line numbering**: 1-based (line 1 is the first line)
- **Memory allocation**: Dynamic with automatic growth
- **Initial buffer**: 1 KiB
- **Growth factor**: 2x when buffer is full
- **Maximum line number**: 2^64-1 (uint64_t)

## Performance

The tool uses dynamic memory allocation starting with a 1 KiB buffer that grows as needed, making it efficient for both short and extremely long lines. It reads character-by-character which is simple and reliable for line-by-line processing.

## License

See LICENSE file for details.

## Contributing

Feel free to submit issues or pull requests!

## Author

Built with ❤️ for simple, reliable line extraction.
