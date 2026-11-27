# G2 note: the FREE -> FREEBX rename (kearfott1990-intbis-681)

Status: evidence for the G2 decision. This note does not satisfy G2 by itself, and no exempt class is claimed.

## The change

- Token diff against the archive's own lines 94-9717 (evidence/rename-diff-vs-archive-range.txt):
  - line 2851: `CALL FREE(CURPTR,MAXLST,UNUSED)` becomes `CALL FREEBX(CURPTR,MAXLST,UNUSED)`
  - line 9243: `SUBROUTINE FREE(BOXPTR,MAXLST,UNUSED)` becomes `SUBROUTINE FREEBX(BOXPTR,MAXLST,UNUSED)`
- Two lines changed, both identifiers. No statement, argument list, constant, loop bound or output format changes.
- Reason: gfortran rejects the package's subroutine FREE ("Too many arguments in call to 'free'") because it collides with the C library free. Without the rename the archive does not build (evidence/original-attempt-build.log).

## Paper check (scanned paper, public: reliable-computing.org scans_of_older_papers/INTBIS_TOMS_article.pdf, 6 pages, read page by page)

- Sec. 3 lists FREE among the stack-management routines. It names no identifier clash and no renamed routine.
- Sec. 4 says installers may set machine-dependent constants. This is consistent with the D1MACH DATA finding (evidence/problem1-diff.txt), but it does not cover the rename.
- No paper section describes the name FREE, FREEBX, or any identifier change. So no section can be cited for the rename.

## Why it is not build-only or extraction

- The patch edits source bytes (two lines in intbis.f), so the build-only and extraction rules in docs/method.md do not apply. The full G2 check stands.

## Question for scout

- Does a rename of two identifiers, with no statement, parameter or output change and no paper counterpart, pass G2 under the full check? The method text gives no exemption class for this. If the answer is no, the verdict is blocked and names G2.
- Not in scope for this note: loosening the tolerance, or the 26-line sample-output difference (evidence/problem1-diff.txt).
