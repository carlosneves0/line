#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

#define INITIAL_BUFFER_SIZE 1024
#define BUFFER_GROWTH_FACTOR 2

// Parse line number with proper error checking
int parse_line_number(const char *str, uint64_t *result);

// Read a line with dynamic memory allocation
// Returns: pointer to line string (caller must free), or NULL on error/EOF
char *read_line_dynamic(FILE *input, int *reached_eof);

int main(int argc, const char **argv)
{
	uint64_t target_line;
	FILE *input = NULL;
	const char *file_name = NULL;
	int exit_code = 0;

	// Parse command line arguments
	if (argc == 2)
	{
		if (parse_line_number(argv[1], &target_line) != 0)
			return 1;
		input = stdin;
	}
	else if (argc == 3)
	{
		if (parse_line_number(argv[1], &target_line) != 0)
			return 1;
		
		file_name = argv[2];
		errno = 0;
		input = fopen(file_name, "r");
		
		if (!input)
		{
			fprintf(stderr, "Error: cannot open '%s': %s\n", file_name, strerror(errno));
			return 1;
		}
	}
	else 
	{
		const char *arg0 = argc > 0 ? argv[0] : "line";
		fprintf(stderr, "Usage: %s LINE_NUMBER [FILE]\n", arg0);
		fprintf(stderr, "Examples:\n");
		fprintf(stderr, "  %s 3 file.txt               # Print line 3 from file.txt\n", arg0);
		fprintf(stderr, "  grep xyz file.txt | %s 1    # Print first matching line\n", arg0);
		return 1;
	}

	if (target_line == 0)
	{
		fprintf(stderr, "Error: line cannot be zero\n");
		return 1;
	}

	// Read lines until we reach the target
	uint64_t current_line = 1;
	char *line_content = NULL;
	int reached_eof = 0;
	
	while (current_line <= target_line)
	{
		// Free previous line content
		if (line_content)
		{
			free(line_content);
			line_content = NULL;
		}
		
		line_content = read_line_dynamic(input, &reached_eof);
		
		if (!line_content)
		{
			// Reached EOF before finding the target line
			current_line -= 1;
			if (file_name)
				fprintf(stderr, "Error: line %"PRIu64" not found in '%s' (file has %"PRIu64" line%s)\n",
					target_line, file_name, current_line, current_line == 1 ? "" : "s");
			else
				fprintf(stderr, "Error: line %"PRIu64" not found in stdin (input has %"PRIu64" line%s)\n",
					target_line, current_line, current_line == 1 ? "" : "s");
			exit_code = 1;
			goto cleanup;
		}
		
		if (current_line == target_line)
		{
			// Found the target line
			printf("%s\n", line_content);
			goto cleanup;
		}
		
		current_line += 1;
	}

cleanup:
	if (line_content)
		free(line_content);
	
	if (input && input != stdin)
		fclose(input);
	
	return exit_code;
}

int parse_line_number(const char *str, uint64_t *result)
{
	char *endptr;
	
	// Check for empty string or leading whitespace
	if (!str || !*str || isspace(*str))
	{
		fprintf(stderr, "Error: line number cannot be empty or start with whitespace\n");
		return 1;
	}
	
	errno = 0;
	unsigned long long val = strtoull(str, &endptr, 10);
	
	// Check for conversion errors
	if (errno == ERANGE)
	{
		fprintf(stderr, "Error: line number is out of range\n");
		return 1;
	}
	
	// Check if any conversion happened and entire string was consumed
	if (endptr == str || *endptr != '\0')
	{
		fprintf(stderr, "Error: '%s' is not a valid line number\n", str);
		return 1;
	}
	
	*result = (uint64_t)val;
	return 0;
}

char *read_line_dynamic(FILE *input, int *reached_eof)
{
	size_t buffer_size = INITIAL_BUFFER_SIZE;
	size_t i = 0;
	char *line_str = malloc(buffer_size);
	
	if (!line_str)
	{
		fprintf(stderr, "Error: memory allocation failed\n");
		return NULL;
	}
	
	int c;
	while ((c = fgetc(input)) != EOF)
	{
		if (c == '\n')
			break;
		
		// Resize buffer if needed (leave room for null terminator)
		if (i >= buffer_size - 1)
		{
			size_t new_size = buffer_size * BUFFER_GROWTH_FACTOR;
			char *new_buffer = realloc(line_str, new_size);
			
			if (!new_buffer)
			{
				fprintf(stderr, "Error: memory reallocation failed (line too long)\n");
				free(line_str);
				return NULL;
			}
			
			line_str = new_buffer;
			buffer_size = new_size;
		}
		
		line_str[i++] = (char)c;
	}
	
	// Check if we read anything
	if (i == 0 && c == EOF)
	{
		free(line_str);
		*reached_eof = 1;
		return NULL;
	}
	
	line_str[i] = '\0';
	*reached_eof = (c == EOF);
	return line_str;
}