/***/ static char *pgmid = "CHORD.C 1.0 copyright 1987 S. Savitzky";

/*********************************************************************\
**
**	CHORD -- print lyrics with chords
**	
**		-i n		indent (default 8)
**		-O file		output to file	(default STDOUT)
**		file		input from file (default STDIN)
**	
**	8702xx SS	create
**
\*********************************************************************/

#include <stdio.h>
#include "scanner.h"
#include "dates.h"

#define global
#define local	static
#define DEBUG	if (debugf) {
#define DEBEND }
global int debugf = 0;

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned long ulong;

#define ENDCHR ';'
#define BCHORD '['
#define ECHORD ']'


/*********************************************************************\
**
**	V A R I A B L E S
**	
\*********************************************************************/

FILE *f;			/* -F option file 			*/
char buf[512];		/* general-purpose buffer	*/
int tabstop = 8;	/* default tabstop			*/
int indent = 8;		/* default indentation		*/


/*********************************************************************\
**
** n = copy(dst, src, flag)		
**
**		copy string src into buffer dst.
**			flag = 0: copy lyrics
**			flag = 1: copy chords
**		Return the length of dst, not counting the final null.
**
**		If no chords/lyrics present, the length will be 0,
**		otherwise it will be at least 1 (the linefeed at the end).
**
\*********************************************************************/

int copy(dst, src, flag)
	char *dst, *src;
	int flag;
{
	int scol, dcol, state;
	char *p = dst;

	state = 0;
	for (scol = dcol = 0; *src && *src != '\n'; ++src) {
		switch (*src) {
		 case BCHORD:
		 	++state;
			break;
		 case ECHORD:
		 	--state;
			break;
		 case '\t':
		 	if (state == 0) {
				do {++scol;} while (scol % tabstop);
		 	} else if (state == flag) {
				do {
					*p++ = ' ';
					++dcol;
				} while (dcol % tabstop);
			}
		 	break;
		 default:
			if (state == flag) {
				while (dcol < scol) {
					*p++ = ' ';
					++dcol;
				}
				*p++ = *src;
				++dcol;
			}
		 	if (state == 0) {
				++scol;
		 	}
		}
	}
	if (dcol) *p++ = '\n';
	*p = 0;
	return(p - dst);
}


/*********************************************************************\
**
**	M A I N   P R O G R A M
**	
\*********************************************************************/

main(argc, argv)
int    argc;
char **argv;
{
	char c;
	char obuf[256];

	scnCmd(argc, argv, (char *)NULL);
	for (scnSkp(); scnPtr; scnSkp()) {
		switch (c = scnOpt()) {
			case 'I': case 'i':					/* -I n indent */
				indent = scnNum(10);
				break;
			case 'O': case 'o':					/* -O f	output file */
				scnOpS(buf, sizeof(buf));
				if (!freopen(buf, "w", stdout)) {
					fprintf(stderr, 
							"%s: output file '%s' not found\n", argv[0], buf); 
					exit(-1); 
				}
				break;
			case 'Z': case 'z':					/* -Z	debug			*/
				debugf = 1;
				break;
			case 0: 							/* not a flagged option */
				scnOpS(buf, sizeof(buf));
DEBUG printf("input filename = '%s'\n", buf); DEBEND
				if (!freopen(buf, "r", stdin)) {
					fprintf(stderr, 
							"%s: input file '%s' not found\n", argv[0], buf); 
					exit(-1); 
				}
				break;

			default:
				fprintf(stderr, 
						"%s: unknown option: '%c%s'\n", argv[0], c, scnPtr);
				scnWrd((char *)NULL, 0);
				break;
		}
	}

	while (!feof(stdin)) {
		buf[0] = ENDCHR;
		gets(buf);
		if (buf[0] == ENDCHR) break;
		if (copy(obuf, buf, 1)) printf("%*s%s", indent, "", obuf);
		if (copy(obuf, buf, 0)) printf("%*s%s", indent, "", obuf);
		else					putchar('\n');
	}
	putchar('\f');
	exit(0);
}
