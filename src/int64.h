#ifndef __INT64_H__
#define __INT64_H__

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

bool parse_int64(const char *s, int64_t *x)
{
	char *end;
	
	errno = 0;
	
	*x = (int64_t) strtoll(s, &end, 10);
	
	if (end == s || *end != '\0')
		return false; // Error: invalid input or extra characters
	
	if (errno == ERANGE)
		return false; // Error: overflow/underflow
	
	return true; // OK
}

#endif