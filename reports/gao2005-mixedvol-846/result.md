# gao2005-mixedvol-846: result

**Verdict: reproduced.** Basis: **patched (build-only)**.

## Claim

TOMS 846 (MixedVol, C++). The manual's worked three-polynomial system (`Doc/userman.tex`,
'Call Sequence and Output') has mixed volume **119** by the manual's statement. Integer,
`tol_abs` 0, fixed in the queue entry before any run. The article was not read (paywalled).

## Our value

- Pass 1: **119**
- Pass 2: **119** (clean rebuild from the unpacked archive)
- Manual: **119**
- Difference 0.

## Basis and why

The authors' procedure does not run as documented. The manual says to run `build` in the
main directory; there is no such script. The shipped `Doc/makefile` is the code's makefile
(not a manual makefile, despite the queue note). Run from the main directory it stops with
`No rule to make target 'MixedVolDriver.o'`; run from `Src/` it stops at
`MixedVolDriver.cpp:189` and `:209` (`INT_MAX` not declared: `<climits>` is not included and
current g++ does not include it transitively). The original attempt is therefore `failed`.

The build we ran uses the makefile's own commands (`g++ -c -O2 -ansi`, then the link) with one
compiler flag, `-include climits`, which supplies the missing declaration. No source file was
edited: the build-only record (`verify_sources record`, exit 0) shows 30 source files unchanged
and no tool-added source. The link names the object paths explicitly, because the makefile's link
line omits the `PolyReader/` prefix. The basis is `patched`, not `original`.

## The input

The manual's system was typed into `MyPolynomials` outside the archive (scratch input directory)
as the manual's syntax (`{ ... }` with one `;`-terminated polynomial per line). Its content is in
`evidence/recipe-run.log`.

## Exact command

```
bash reports/gao2005-mixedvol-846/recipe.sh
```

Pins: g++ 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1), `-O2 -ansi -include climits`.
Archive sha256 `c1a8045a45878744ac58078c696f54b1166d8c3a7fdca00ff0a66c41bca9acdb`.

## Evidence

`reports/gao2005-mixedvol-846/evidence/`: `fetch-toolchain.log`, `unpack.log`,
`original-attempt-root.log`, `original-attempt-src.log`, `pass1-build.log`, `pass1-run.log`,
`pass1-output.txt`, `pass2-run.log`, `pass2-output.txt`, `reference-block.txt`, `values.txt`,
`record.log`, `manifest.{pre,mid,post}`.
