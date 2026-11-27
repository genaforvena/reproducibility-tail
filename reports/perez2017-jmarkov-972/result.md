# perez2017-jmarkov-972 (TOMS 972, JMarkov, Java)

**Verdict:** reproduced. **Basis:** original (the authors' shipped jar and shipped test ran as documented).

## Claim (registered, not edited)

`getMOPsAvg()[0]` of the Kanban model (`examples.jmarkov.Kanban`, default parameters) equals 0.7003166576899312, the
value in the shipped `KanbanTest.testGetMOPsAvg`, with absolute tolerance 1e-4.

## Values

| value | shipped | pass 1 | pass 2 | difference | verdict |
|---|---|---|---|---|---|
| Kanban MOPs avg [0] | 0.7003166576899312 | 0.7003166565882202 | 0.7003166565882202 | 1.1e-9 (1.1e-5 of tol) | match |

## What happened

1. **Original attempt (G1), succeeded.** The shipped `lib/jMarkov.jar` and the shipped test class `jmarkov.KanbanTest`
   ran with `junit.textui.TestRunner`: `OK (3 tests)`, including `testGetMOPsAvg` (all seven MOPs within 1e-4). Log:
   `evidence/original-attempt.log`. Third-party dependencies (MTJ 1.0 from the INSTALL list, JUnit 4.13.2) come from
   Maven Central with sha256 checked in the recipe. They are environment pins, not patches.
2. **Harness.** `impl/PrintKanban.java` only calls `getMOPsAvg()` with the default parameters and prints the first
   entry. It adds no model code. Two passes, each a fresh JVM run of the harness against the authors' jar (pass 2
   recompiles first). Outputs: `evidence/pass1-output.txt`, `evidence/pass2-output.txt`.
3. **Sandbox change.** The first harness compile failed inside the sandbox: JDK 17 `javac` could not read its security
   configuration, because `/usr/lib/jvm/java-17-openjdk-amd64/conf/security/java.security` is a symlink into
   `/etc/java-17-openjdk`, which the sandbox does not bind. `tools/sandbox.sh` now binds that directory read-only
   (`--ro-bind-try`). It is a single read-only line; no other sandbox behaviour changed.

## Environment pins

- Archive: netlib `972.zip`, sha256 `2287337098bfa3d4086ad1363a9b39ac53983d98d788cc950f1cbdb5c2bf1df7` (checked at fetch).
- MTJ 1.0 `mtj-1.0.jar`, sha256 `03ccf32907fc65878ce447354bc462ca909131f7b3a7ea123b3ce983d14ec746`.
- JUnit 4.13.2 `junit-4.13.2.jar`, sha256 `8e495b634469d64fb8acfa3495a065cbacc8a0fff55ce1e31007be4c16dc57d3`.
- JDK: OpenJDK 17.0.21.1 (Ubuntu) on the host, used inside the sandbox.

## Caveats

- The claim is one entry of a steady-state solve, reproduced at 1e-9. A different solver order would still pass at this tolerance.
- The shipped jar was used, not a from-source build (the build file and third-party jars are not in the archive).

## Reproduce

`bash reports/perez2017-jmarkov-972/recipe.sh`
