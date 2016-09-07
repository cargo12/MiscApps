/*	$FreeBSD$	*/
/*	$OpenBSD: diff.h,v 1.29 2004/12/09 18:56:10 millert Exp $	*/

/*-
 * Copyright (c) 1991, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	@(#)diff.h	8.1 (Berkeley) 6/6/93
 */

#include <sys/types.h>

#include <regex.h>

/*
 * Output format options
 */
#define	D_NORMAL	0	/* Normal output */
#define	D_EDIT		-1	/* Editor script out */
#define	D_REVERSE	1	/* Reverse editor script */
#define	D_CONTEXT	2	/* Diff with context */
#define	D_UNIFIED	3	/* Unified context diff */
#define	D_IFDEF		4	/* Diff with merged #ifdef's */
#define	D_NREVERSE	5	/* Reverse ed script with numbered
				   lines and no trailing . */
#define	D_BRIEF		6	/* Say if the files differ */
#define D_GF		7	/* Group format */
#define	D_LF		8	/* Line format */

/*
 * Output flags
 */
#define	D_HEADER	1	/* Print a header/footer between files */
#define	D_EMPTY1	2	/* Treat first file as empty (/dev/null) */
#define	D_EMPTY2	4	/* Treat second file as empty (/dev/null) */

/*
 * Status values for print_status() and diffreg() return values
 */
#define	D_SAME		0	/* Files are the same */
#define	D_DIFFER	1	/* Files are different */
#define	D_BINARY	2	/* Binary files are different */
#define	D_COMMON	3	/* Subdirectory common to both dirs */
#define	D_ONLY		4	/* Only exists in one directory */
#define	D_MISMATCH1	5	/* path1 was a dir, path2 a file */
#define	D_MISMATCH2	6	/* path1 was a file, path2 a dir */
#define	D_ERROR		7	/* An error occurred */
#define	D_SKIPPED1	8	/* path1 was a special file */
#define	D_SKIPPED2	9	/* path2 was a special file */

/*
 * File input types
 */
#define FILE_NORMAL	0
#define FILE_GZIP	1

struct excludes {
	char		*pattern;
	struct excludes	*next;
};

extern int	 aflag, bflag, cflag, dflag, Eflag, Fromflag, iflag, lflag, Nflag, Pflag, pflag, rflag,
		 sflag, tflag, Tflag, Toflag, wflag;
extern int	 Bflag, strip_cr, suppress_cl, tabsize;
extern int	 format, context, status;
extern int	 filebehave;
extern char	 ignore_file_case;
extern char	*start, *ifdefname, *diffargs, *label[2], *ignore_pats;
extern struct	 stat stb1, stb2;
extern struct	 excludes *excludes_list;
extern regex_t	 ignore_re;

char	*splice(char *, char *);
int	diffreg(char *, char *, int);
int	easprintf(char **, const char *, ...);
void	*emalloc(size_t);
void	*erealloc(void *, size_t);
void	diffdir(char *, char *);
void	print_only(const char *, size_t, const char *);
void	print_status(int, char *, char *, char *);

FILE *decompressfile(char *, char *);
int isgzip(char *);