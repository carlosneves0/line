CC = gcc
CFLAGS = -Wall -Wextra -Werror -std=c99 -O2
LDFLAGS =
TARGET = line
SRC = main.c
PREFIX ?= /usr/local

# Build the executable
all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

# Debug build with symbols and no optimization
debug: CFLAGS = -Wall -Wextra -std=c99 -g -O0 -DDEBUG
debug: clean $(TARGET)

# Install to system
install: $(TARGET)
	install -d $(PREFIX)/bin
	install -m 755 $(TARGET) $(PREFIX)/bin/

# Uninstall from system
uninstall:
	rm -f $(PREFIX)/bin/$(TARGET)

# Run tests
test: $(TARGET)
	@echo "Running tests..."
	sh test.sh

# Clean build artifacts
clean:
	rm -f $(TARGET)
	rm -rf test_output/

# Format code (requires clang-format)
format:
	clang-format -i $(SRC)

# Check for memory leaks (requires valgrind)
memcheck: $(TARGET)
	@echo "Checking for memory leaks..."
	valgrind --leak-check=full --error-exitcode=1 ./$(TARGET) 0
# @echo "first line" | valgrind --leak-check=full --error-exitcode=1 ./$(TARGET) 0 2>&1 | grep -q "ERROR SUMMARY: 0 errors"

.PHONY: all debug install uninstall test clean format memcheck

