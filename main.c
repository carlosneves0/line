#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
// #include <errno.h>
// TO-DO: error handling...

#define MiB 1048576
#define KiB 1024

extern int errno;

int main(int argc, char **argv)
{
	// /*DEBUG*/printf("argc = %d\n", argc);

	uint64_t line;
	FILE *input;

	if (argc == 2)
	{
		line = (uint64_t) strtoull(argv[1], NULL, 10);
		input = stdin;
		// /*DEBUG*/printf("input = stdin\n");
	}
	else if (argc == 3)
	{
		line = (uint64_t) strtoull(argv[1], NULL, 10);
		
		errno = 0;
		input = fopen(argv[2], "r");
		if (!input)
		{
			fprintf(stderr, "Error: %s\n", strerror(errno));
			return 1;
		}
		// /*DEBUG*/printf("input = %s\n", argv[2]);
	}
	else 
	{
		fprintf(stderr, "Error: usage: `line 3 file.txt`\n");
		fprintf(stderr, "Error: usage: `grep xyz file.txt | line 1`\n");
		return 1;
	}
	// /*DEBUG*/printf("line = %"SCNu64"\n", line);

	// NOTE: assuming line max-length of 1 MiB.
	// TO-DO: dynamically allocate more memory if needed...
	char c;
	uint64_t l = 0,
		i = 0;
	char line_str[1 * MiB];
	line_str[0] = '\0';
	while ((c = fgetc(input)) != EOF)
	{
		// /*DEBUG*/printf("l=%"SCNu64" i=%"SCNu64" c=%c line=\"%s\"\n", l, i, c, line_str);
		if (l == line)
			break;
		if (c == '\n')
		{
			l += 1;
			line_str[i] = '\0';
			i = 0;
			continue;
		}
		line_str[i] = c;
		// /*DEBUG*/line_str[i+1] = '\0';
		i += 1;
	}

	if (l != line)
	{
		if (input == stdin)
			fprintf(stderr, "Error: line %s not in stdin\n", argv[1]);
		else
			fprintf(stderr, "Error: line %s not in file %s\n", argv[1], argv[2]);
		return 1;
	}

	printf("%s\n", line_str);
	
	if (input != stdin)
		fclose(input);
	
	return 0;
}