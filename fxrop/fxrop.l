%{
#include <string.h>

struct sym {
	char *n, *v;
} syms[128];
size_t nsyms;
char *args[128];
size_t nargs;

char *symfind(char *n);

void err(const char *s);

char *imm(char *s);

%}

immediate ((\"\"[^(\"\")]*\"\")|(0x[0-9a-zA-Z]+))

symbol ([0-9a-zA-Z]+)

%x COMMENT

%%

^{symbol}[ \t]*=[ \t]*{immediate} {
	char *n, *v;
	if (nsyms == sizeof(syms))
		err("too many symbol definitions");
	n = strdup(yytext);
	*strpbrk(n, " \t=") = 0;
	v = imm(strchr(yytext, '='));
	syms[nsyms++] = (struct sym){n, v};
		}

^($${symbol})|{immediate} {
	char *s;
	if (nargs == sizeof(args)) 
		err("too many args");
	if (*yytext == '$') {	/* symbol */
		s = strdup(yytext + 2);
		if ((s = symfind(s)) == NULL)
			err("unknown symbol");
	} else {		/* immediate value */
		s = imm(yytext);
	}
	args[nargs++] = s;
		}

;.* BEGIN(COMMENT);

<COMMENT>\n { ++yylineno; BEGIN(0); }

[^ \t\r\n] err(NULL);

[ \t\r]

\n ++yylineno;

%%

/*
 * Obtain immediate value from `s`, which must point to a string
 * that either is, or contains and ends with, a valid representation of an
 * immediate value.
 */
char *
imm(char *s)
{
	char *r;
	if ((r = strstr(s, "0x")) == NULL) {
		r = strdup(strchr(s, '"') + 1);
		r[strlen(r) - 1] = 0;
	} else {
		r = strdup(r);
	}
	return r;
}

char *
symfind(char *n) 
{
	int i;
	for (i = 0; i < nsyms; ++i)
		if (!strcmp(syms[i].n, n))
			return syms[i].v;
	return NULL;
}

void
err(const char *s) 
{
	if (s != NULL)
		fprintf(stderr, "error at line %d: %s\n", yylineno, s);
	else
		fprintf(stderr, "error at line %d\n", yylineno);
	exit(1);
}

int 
yywrap(void) { return 1; }

main()
{
	int i;
	yylex();
	for (i = nargs-1; i >= 0; --i)
		fprintf(yyout, "%s%s", args[i], (i == 0) ? "" : ",");
	fputc('\n', yyout);
	fprintf(stderr, "%zu args formatted.\n", nargs);
	return 0;
}
