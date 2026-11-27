#!/usr/bin/env bash
# Rebuilds the rerun record for perez2017-jmarkov-972 (TOMS 972, jMarkov, Java).
# Everything that runs the authors' code goes through tools/sandbox.sh.
#
# Fetch (the only network step, inside the sandbox): netlib TOMS 972.zip (sha256 checked against the queue entry),
# unzipped to /work/pre; and two third-party jars the shipped test needs, MTJ 1.0 (listed in Java/INSTALL.txt) and
# JUnit 4.13.2 (junit.framework), from Maven Central, sha256 checked against the values recorded here.
#
# Original attempt (G1): the authors' shipped lib/jMarkov.jar with their shipped test class jmarkov.KanbanTest, run
# with junit.textui.TestRunner. No source is compiled and nothing is edited. Log: evidence/original-attempt.log.
#
# Claim: the first entry of getMOPsAvg() of examples.jmarkov.Kanban with default parameters, against the shipped
# expected value 0.7003166576899312, absolute tolerance 1e-4 (fixed in the queue entry). The harness
# impl/PrintKanban.java only calls that method and prints the value. Two passes (G3): each pass is a fresh JVM run of
# the harness against the authors' jar (the second pass recompiles the harness first).
set -uo pipefail
ID=perez2017-jmarkov-972
URL=https://netlib.org/toms/972.zip
SHA=2287337098bfa3d4086ad1363a9b39ac53983d98d788cc950f1cbdb5c2bf1df7
MTJ_SHA=03ccf32907fc65878ce447354bc462ca909131f7b3a7ea123b3ce983d14ec746
JUNIT_SHA=8e495b634469d64fb8acfa3495a065cbacc8a0fff55ce1e31007be4c16dc57d3
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
E="$root/reports/$ID/evidence"
LOG="${LOG:-$E/recipe-run.log}"
SCRATCH=/mnt/mishe-scratch/reproducibility-tail/$ID
mkdir -p "$E"
cd "$root"
exec > >(tee "$LOG") 2>&1
CP='/work/pre/972/Java/jMarkov/lib/jMarkov.jar:/work/deps/mtj-1.0.jar:/work/deps/junit-4.13.2.jar'

echo "== fetch: 972.zip (sha256 checked), unzipped; MTJ 1.0 and JUnit 4.13.2 (sha256 checked)"
tools/sandbox.sh --fetch "$ID" -- sh -c "set -e; mkdir -p /work/pre /work/deps && cd /work/pre && curl -fsSL -o /work/972.zip '$URL'; echo '$SHA  /work/972.zip' | sha256sum -c -; unzip -qo /work/972.zip; \
  cd /work/deps && curl -fsSL -o mtj-1.0.jar https://repo1.maven.org/maven2/com/googlecode/matrix-toolkits-java/mtj/1.0/mtj-1.0.jar && echo '$MTJ_SHA  mtj-1.0.jar' | sha256sum -c - && \
  curl -fsSL -o junit-4.13.2.jar https://repo1.maven.org/maven2/junit/junit/4.13.2/junit-4.13.2.jar && echo '$JUNIT_SHA  junit-4.13.2.jar' | sha256sum -c -" || { echo "FETCH-FAILED"; exit 1; }

echo "== original attempt (G1): the authors' shipped jar and shipped test class jmarkov.KanbanTest, run as TestRunner"
tools/sandbox.sh "$ID" -- sh -c "cd /work/pre/972/Java/jMarkov && java -cp '$CP' junit.textui.TestRunner jmarkov.KanbanTest; echo test_exit=\$?" > "$E/original-attempt.log" 2>&1
tail -4 "$E/original-attempt.log"

echo "== harness: compile impl/PrintKanban.java against the authors' jar (pass 2 recompiles; pass 1 compiles here)"
mkdir -p "$SCRATCH/harness"
cp "$here/impl/PrintKanban.java" "$SCRATCH/harness/PrintKanban.java"
for pass in 1 2; do
  tools/sandbox.sh "$ID" -- sh -c "rm -rf /work/harness-$pass && mkdir /work/harness-$pass && cp /work/harness/PrintKanban.java /work/harness-$pass/ 2>/dev/null; cd /work/harness-$pass && javac -cp '$CP' -d . PrintKanban.java && java -cp '$CP':. PrintKanban > /work/pass$pass.out 2>/work/pass$pass.err; echo rc_pass$pass=\$?" > "$E/pass$pass-run.log" 2>&1
  grep -E "rc_pass" "$E/pass$pass-run.log"
done
for pass in 1 2; do cp "$SCRATCH/pass$pass.out" "$E/pass$pass-output.txt" 2>/dev/null; cp "$SCRATCH/pass$pass.err" "$E/pass$pass-stderr.txt" 2>/dev/null; done

mkdir -p "$E/reference" && cp "$SCRATCH/pre/972/Java/jMarkov/test/jmarkov/KanbanTest.java" "$E/reference/KanbanTest.java"

echo "== values: the Kanban MOPs avg [0], both passes"
python3 -I - "$E/pass1-output.txt" "$E/pass2-output.txt" <<'PY' > "$E/values.txt" || true
import sys
def v(path):
    for line in open(path):
        if line.startswith("VALUE "):
            return float(line.split()[-1])
    return None
a = v(sys.argv[1]); b = v(sys.argv[2])
print("pass1", a)
print("pass2", b)
print("agree", a == b)
PY
cat "$E/values.txt"

# The G5 replay reads one VALUE line per claimed value, named as in result.json.
V=$(grep '^VALUE ' "$E/pass1-output.txt" | awk '{print $NF}')
echo "VALUE Kanban MOPs avg [0] ${V:-nan}"
