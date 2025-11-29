#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "int64.h"

#define OK          0
#define ERR_RUNTIME 1
#define ERR_ARGV    2
#define ERR_RANGE   3
#define ERR_TO_DO   4

#define _EXIT(_code) do { code = (_code); goto exit; } while (false)

int code = OK;

int main(int argc, const char **argv)
{
	const char *arg0 = argc >= 1 ? argv[0] : "line";
	int64_t line;
	FILE *file = NULL;
	// bool reverse = false;

	/* Parse argv */
	if (argc == 2)
	{
		if (!parse_int64(argv[1], &line))
			_EXIT(ERR_ARGV);
		file = stdin;
	}
	else if (argc == 3)
	{
		if (!parse_int64(argv[1], &line))
			_EXIT(ERR_ARGV);
		file = fopen(argv[2], "r");
		if (!file)
		{
			fprintf(stderr, "%s: %s: %s\n", arg0, argv[2], strerror(errno));
			_EXIT(ERR_RUNTIME);
		}
	}
	else
	{
		fprintf(stderr, "usage: %s [line-number] [file]\n", arg0);
		fprintf(stderr, "examples:\n");
		fprintf(stderr, "  %s 3 file.txt               # Print line 3 from file.txt\n", arg0);
		fprintf(stderr, "  grep xyz file.txt | %s 1    # Print first matching line\n", arg0);
		_EXIT(ERR_ARGV);
	}

	/* Handle line values */
	if (line == 0)
	{
		// Should this be an explicit error?
		// fprintf(stderr, "%s: line cannot be zero\n", arg0);
		// _EXIT(ERR_ARGV);
		// Or simply a no-op?
		_EXIT(OK);
	}
	else if (line < 0)
	{
		line *= -1;
		// reverse = true;
		fprintf(stderr, "TO-DO: \"reversed\" line\n");
		// Reverse for pipes will require dynamic memory...
		_EXIT(ERR_TO_DO);
	}

	/* Read input file and print matching line */
	int64_t l = 1;
	int c;
	while ((c = fgetc(file)) != EOF)
	{
		if (c == '\n')
		{
			l += 1;
			continue;
		}
		
		if (l == line)
			printf("%c", c);
	}
	if (line <= l)
		printf("\n");
	else
		_EXIT(ERR_RANGE); // input file has no such line

exit:
	if (file)
		fclose(file);

	return code;
}