CC := gcc
CFLAGS := -Wall -Wextra -Werror -std=c99 -O3
LDFLAGS :=
TARGET := line
SRC := $(shell find src -type f -name '*.c')
PREFIX ?= /usr/local/bin

.DEFAULT_GOAL := $(TARGET)

# Build the executable
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

# Debug build with symbols and no optimization
debug: CFLAGS = -Wall -Wextra -std=c99 -g -O0 -DDEBUG
debug: clean $(TARGET)

# Install to system
install: $(TARGET)
	install -d $(PREFIX)
	install -m 755 $(TARGET) $(PREFIX)

# Uninstall from system
uninstall:
	rm -f $(PREFIX)/$(TARGET)

# Run tests
test: $(TARGET)
	bash test/main.bash

# Clean build artifacts
clean:
	rm -f $(TARGET)

# Format code (requires clang-format)
format:
	clang-format -i $(SRC)

# Check for memory leaks (requires valgrind)
valgrind: $(TARGET)
	@echo "Checking for memory leaks..."
	valgrind --leak-check=full --error-exitcode=1 ./$(TARGET) 0
# @echo "first line" | valgrind --leak-check=full --error-exitcode=1 ./$(TARGET) 0 2>&1 | grep -q "ERROR SUMMARY: 0 errors"

.PHONY: debug install uninstall test clean format valgrind

