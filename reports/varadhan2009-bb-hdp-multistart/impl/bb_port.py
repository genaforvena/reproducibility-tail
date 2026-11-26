#!/usr/bin/env python3
# CC0 (public-domain dedication). Written by the rerun mind for the
# varadhan2009-bb-hdp-multistart rerun; not the authors' code.
#
# Reimplementation of the paper's JSS 2009 listing (BB 2009.9-1):
#   p0 <- matrix(runif(900), 300, 3) after set.seed(1234) (Mersenne-Twister)
#   ans <- multiStart(par = p0, fn = hdp, action = "solve")
#   sum(ans$conv)            # the registered claim: 284 (tolerance 281..287)
#
# Ported line by line from the R sources, read in place:
#   BB 2009.9-1: R/BBsolve.R, R/dfsane.R, R/multiStart.R, paper listing
#   R 4.6.2 (src/main/RNG.c: seeding and MT_genrand, src/appl/optim.c: nmmin)
# Known differences, recorded in reports/varadhan2009-bb-hdp-multistart/result.md:
#   R accumulates sum() in long double; this port uses double.
#   Only the 'solve' path of multiStart is ported (no BBoptim).
#
# Usage (inside the sandbox): python3 -I bb_port.py [--self-test]
import math
import sys

INF = float("inf")
NAN = float("nan")
BIG = 1.0e35                      # optim.c: #define big 1.0e+35
SQRT_EPS = 1.4901161193847656e-08  # optim(): reltol default sqrt(.Machine$double.eps)
I2_32M1 = 2.328306437080797e-10   # RNG.c: 1/(2^32 - 1)


class RError(Exception):
    """An R-level stop() or error(); BBsolve/multiStart catch these with try()."""


def finite(v):
    return not (math.isnan(v) or math.isinf(v))


def sgn(v):
    if math.isnan(v):
        return NAN
    return 1.0 if v > 0 else (-1.0 if v < 0 else 0.0)


def dv(a, b):
    """R double division: x/0 gives +-Inf, 0/0 gives NaN (no exception)."""
    try:
        return a / b
    except ZeroDivisionError:
        if a == 0 or math.isnan(a):
            return NAN
        return math.copysign(INF, a) * math.copysign(1.0, b)


def rsqrt(v):
    if math.isnan(v):
        return v
    return math.sqrt(v) if v >= 0 else NAN


def pw(x, k):
    """R's x^k for a double x and integer-valued k (no exception on overflow)."""
    if k == 2:
        return x * x
    try:
        return x ** k
    except OverflowError:
        return INF if (x > 0 or k % 2 == 0) else -INF


def rsum(values):
    s = 0.0
    for v in values:
        s += v
    return s


# ---------------------------------------------------------------- RNG (RNG.c)

N_MT, M_MT = 624, 397
MATRIX_A, UPPER_MASK, LOWER_MASK = 0x9908B0DF, 0x80000000, 0x7FFFFFFF


class MersenneTwister:
    def __init__(self, mt, mti):
        self.mt = list(mt)
        self.mti = mti

    def genrand(self):
        mt = self.mt
        if self.mti >= N_MT:
            for kk in range(N_MT - M_MT):
                y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK)
                mt[kk] = mt[kk + M_MT] ^ (y >> 1) ^ (MATRIX_A if y & 1 else 0)
            for kk in range(N_MT - M_MT, N_MT - 1):
                y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK)
                mt[kk] = mt[kk + (M_MT - N_MT)] ^ (y >> 1) ^ (MATRIX_A if y & 1 else 0)
            y = (mt[N_MT - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK)
            mt[N_MT - 1] = mt[M_MT - 1] ^ (y >> 1) ^ (MATRIX_A if y & 1 else 0)
            self.mti = 0
        y = mt[self.mti]
        self.mti += 1
        y ^= y >> 11
        y ^= (y << 7) & 0x9D2C5680
        y ^= (y << 15) & 0xEFC60000
        y ^= y >> 18
        return (y & 0xFFFFFFFF) * 2.3283064365386963e-10


def fixup(x):
    if x <= 0.0:
        return 0.5 * I2_32M1
    if 1.0 - x <= 0.0:
        return 1.0 - 0.5 * I2_32M1
    return x


def set_seed_r(seed):
    """R's set.seed(seed) for kind Mersenne-Twister (RNG.c RNG_Init + FixupSeeds)."""
    s = seed & 0xFFFFFFFF
    for _ in range(50):
        s = (69069 * s + 1) & 0xFFFFFFFF
    iseed = []
    for _ in range(N_MT + 1):
        s = (69069 * s + 1) & 0xFFFFFFFF
        iseed.append(s)
    # iseed[0] is mti (dummy[0]); FixupSeeds(initial) sets it to 624.
    return MersenneTwister(iseed[1:], N_MT)


def runif(rng, count):
    return [fixup(rng.genrand()) for _ in range(count)]


def standard_mt_first_output(seed):
    """Reference check only: the standard init_genrand(seed) MT19937 first output."""
    mt = [seed & 0xFFFFFFFF]
    for i in range(1, N_MT):
        prev = mt[-1]
        mt.append((1812433253 * (prev ^ (prev >> 30)) + i) & 0xFFFFFFFF)
    return MersenneTwister(mt, N_MT).genrand() * 4294967296.0


# ------------------------------------------------------------- the function

def hdp(x):
    """Kearfott high-degree polynomial system, as listed in the paper (vignette)."""
    x1, x2, x3 = x
    f1 = 5 * pw(x1, 9) - 6 * pw(x1, 5) * pw(x2, 2) + x1 * pw(x2, 4) + 2 * x1 * x3
    f2 = -2 * pw(x1, 6) * x2 + 2 * pw(x1, 2) * pw(x2, 3) + 2 * x2 * x3
    f3 = x1 * x1 + x2 * x2 - 0.265625
    return [f1, f2, f3]


# ------------------------------------------- R optim Nelder-Mead (optim.c)

def nmmin(n, bvec, fminfn, abstol, intol, alpha, bet, gamm, maxit):
    """Literal port of nmmin() in R's src/appl/optim.c. Returns (X, Fmin, fail, fncount).
    Arrays are indexed exactly as in the C source (0-based), with L/H/C as 1-based."""
    P = [[0.0] * (n + 2) for _ in range(n + 1)]
    fail = 0
    f = fminfn(bvec)
    if not finite(f):
        raise RError("function cannot be evaluated at initial parameters")
    funcount = 1
    convtol = intol * (abs(f) + intol)
    n1 = n + 1
    C = n + 2
    P[n1 - 1][0] = f
    for i in range(n):
        P[i][0] = bvec[i]
    L = 1
    size = 0.0
    step = 0.0
    for i in range(n):
        if 0.1 * abs(bvec[i]) > step:
            step = 0.1 * abs(bvec[i])
    if step == 0.0:
        step = 0.1
    for j in range(2, n1 + 1):
        for i in range(n):
            P[i][j - 1] = bvec[i]
        trystep = step
        while P[j - 2][j - 1] == bvec[j - 2]:
            P[j - 2][j - 1] = bvec[j - 2] + trystep
            trystep *= 10
        size += trystep
    oldsize = size
    calcvert = True
    while True:  # C do { ... } while (funcount <= maxit)
        if calcvert:
            for j in range(n1):
                if j + 1 != L:
                    for i in range(n):
                        bvec[i] = P[i][j]
                    f = fminfn(bvec)
                    if not finite(f):
                        f = BIG
                    funcount += 1
                    P[n1 - 1][j] = f
            calcvert = False
        VL = P[n1 - 1][L - 1]
        VH = VL
        H = L
        for j in range(1, n1 + 1):
            if j != L:
                f = P[n1 - 1][j - 1]
                if f < VL:
                    L = j
                    VL = f
                if f > VH:
                    H = j
                    VH = f
        if VH <= VL + convtol or VL <= abstol:
            break
        for i in range(n):
            temp = -P[i][H - 1]
            for j in range(n1):
                temp += P[i][j]
            P[i][C - 1] = temp / n
        for i in range(n):
            bvec[i] = (1.0 + alpha) * P[i][C - 1] - alpha * P[i][H - 1]
        f = fminfn(bvec)
        if not finite(f):
            f = BIG
        funcount += 1
        VR = f
        if VR < VL:
            P[n1 - 1][C - 1] = f
            for i in range(n):
                f = gamm * bvec[i] + (1 - gamm) * P[i][C - 1]
                P[i][C - 1] = bvec[i]
                bvec[i] = f
            f = fminfn(bvec)
            if not finite(f):
                f = BIG
            funcount += 1
            if f < VR:
                for i in range(n):
                    P[i][H - 1] = bvec[i]
                P[n1 - 1][H - 1] = f
            else:
                for i in range(n):
                    P[i][H - 1] = P[i][C - 1]
                P[n1 - 1][H - 1] = VR
        else:
            if VR < VH:
                for i in range(n):
                    P[i][H - 1] = bvec[i]
                P[n1 - 1][H - 1] = VR
            for i in range(n):
                bvec[i] = (1 - bet) * P[i][H - 1] + bet * P[i][C - 1]
            f = fminfn(bvec)
            if not finite(f):
                f = BIG
            funcount += 1
            if f < P[n1 - 1][H - 1]:
                for i in range(n):
                    P[i][H - 1] = bvec[i]
                P[n1 - 1][H - 1] = f
            else:
                if VR >= VH:
                    calcvert = True
                    size = 0.0
                    for j in range(n1):
                        if j + 1 != L:
                            for i in range(n):
                                P[i][j] = bet * (P[i][j] - P[i][L - 1]) + P[i][L - 1]
                                size += abs(P[i][j] - P[i][L - 1])
                    if size < oldsize:
                        oldsize = size
                    else:
                        fail = 10
                        break
        if not (funcount <= maxit):
            break
    Fmin = P[n1 - 1][L - 1]
    X = [P[i][L - 1] for i in range(n)]
    if funcount > maxit:
        fail = 1
    return X, Fmin, fail, funcount


# ------------------------------------------------ BB 2009.9-1 dfsane (R)

class LineSearchFailure(Exception):
    pass


def lsm(x, fn, F, fval, alfa, M, lastfv, eta, fcnt, bl, state):
    """dfsane.R's inner lsm(). state['fune'] mirrors dfsane's `fune` variable."""
    maxbl, gamma, sigma1, sigma2 = 100, 1e-4, 0.1, 0.5
    lam1 = lam2 = 1.0
    cbl = 0
    fmax = max(lastfv)
    xnew, Fnew, fune = None, None, None
    while cbl < maxbl:
        d = [-alfa * Fi for Fi in F]
        xnew = [xi + lam1 * di for xi, di in zip(x, d)]
        Fnew = fn(xnew)
        fcnt += 1
        if any(math.isnan(v) for v in Fnew):
            return dict(xnew=None, Fnew=None, fcnt=fcnt, bl=bl, lsflag=1, fune=None)
        fune1 = rsum([v * v for v in Fnew])
        if fune1 <= (fmax + eta - (lam1 * lam1 * gamma * fval)):
            if cbl >= 1:
                bl += 1
            return dict(xnew=xnew, Fnew=Fnew, fcnt=fcnt, bl=bl, lsflag=0, fune=fune1)
        xnew = [xi - lam2 * di for xi, di in zip(x, d)]
        Fnew = fn(xnew)
        fcnt += 1
        if any(math.isnan(v) for v in Fnew):
            return dict(xnew=None, Fnew=None, fcnt=fcnt, bl=bl, lsflag=1, fune=None)
        fune2 = rsum([v * v for v in Fnew])
        if fune2 <= (fmax + eta - (lam2 * lam2 * gamma * fval)):
            if cbl >= 1:
                bl += 1
            return dict(xnew=xnew, Fnew=Fnew, fcnt=fcnt, bl=bl, lsflag=0, fune=fune2)
        lamc = dv(2 * fval * lam1 * lam1, 2 * (fune1 + (2 * lam1 - 1) * fval))
        c1, c2 = sigma1 * lam1, sigma2 * lam1
        lam1 = c1 if lamc < c1 else (c2 if lamc > c2 else lamc)
        lamc = dv(2 * fval * lam2 * lam2, 2 * (fune2 + (2 * lam2 - 1) * fval))
        c1, c2 = sigma1 * lam2, sigma2 * lam2
        lam2 = c1 if lamc < c1 else (c2 if lamc > c2 else lamc)
        cbl += 1
    # R: return(list(..., fune = fune)); `fune` is looked up in dfsane's frame.
    if state.get("fune") is None:
        raise RError("object 'fune' not found")
    return dict(xnew=xnew, Fnew=Fnew, fcnt=fcnt, bl=bl, lsflag=2, fune=state["fune"])


def dfsane(par, fn, method, M, maxit=1500, tol=1e-7, noimp=100, NM=False, triter=10):
    n = len(par)
    eps = 1e-10
    alfa = 1.0
    eta = 1.0
    alfa1 = alfa2 = 1.0
    fcnt = 0
    it = 0
    bl = 0
    lastfv = [0.0] * M
    state = {"fune": None}
    par = list(par)

    def U(x):
        return rsum([v * v for v in fn(x)])

    if NM:
        X, _fmin, fail, fncount = nmmin(n, list(par), U, -INF, SQRT_EPS,
                                        1.0, 0.5, 2.0, 100)
        if any(math.isnan(v) for v in X):
            raise RError("Failure in Nelder-Mead Start (NaN value).")
        par = X
        fcnt = fncount

    F = fn(par)
    fcnt += 1
    if any(not finite(v) for v in F):
        raise RError("Failure in initial functional evaluation.")

    F0 = normF = rsqrt(rsum([v * v for v in F]))
    pbest = list(par)
    normF_best = normF
    lastfv[0] = normF * normF
    flag = 0
    knoimp = 0

    while normF / math.sqrt(n) > tol and it <= maxit:
        if abs(alfa) <= eps or abs(alfa) >= 1 / eps:
            if normF > 1:
                alfa = 1.0
            elif normF >= 1e-5 and normF <= 1:
                alfa = dv(1.0, normF)
            elif normF < 1e-5:
                alfa = 1e5
        if it == 0:
            alfa = min(dv(1.0, normF), 1.0)
            alfa1 = alfa2 = alfa
        temp = alfa2
        alfa2 = alfa
        if normF <= 0.01:
            alfa = alfa1
        alfa1 = temp

        ls = lsm(par, fn, F, normF * normF, alfa, M, lastfv, eta, fcnt, bl, state)
        fcnt = ls["fcnt"]
        bl = ls["bl"]
        flag = ls["lsflag"]
        if flag > 0:
            break
        Fnew = ls["Fnew"]
        pnew = ls["xnew"]
        fune = ls["fune"]
        state["fune"] = fune

        pF = rsum([(pn - p) * (fn_ - f_) for pn, p, fn_, f_ in zip(pnew, par, Fnew, F)])
        pp = rsum([(pn - p) ** 2 for pn, p in zip(pnew, par)])
        FF = rsum([(fn_ - f_) ** 2 for fn_, f_ in zip(Fnew, F)])

        if method == 1:
            alfa = dv(pp, pF)
        elif method == 2:
            alfa = dv(pF, FF)
        elif method == 3:
            alfa = sgn(pF) * rsqrt(dv(pp, FF))
        if math.isnan(alfa):
            alfa = eps

        par = pnew
        F = Fnew
        normF = rsqrt(fune)

        if normF < normF_best:
            pbest = list(par)
            normF_best = normF
            knoimp = 0
        else:
            knoimp += 1

        it += 1
        lastfv[it % M] = fune
        eta = dv(F0, (it + 1) ** 2)
        if knoimp == noimp:
            flag = 3
            break

    if flag == 0:
        if normF_best / math.sqrt(n) <= tol:
            ctype = 0
        elif it > maxit:
            ctype = 1
        else:
            ctype = 2
    elif flag == 1:
        ctype = 3
    elif flag == 2:
        ctype = 4
    else:
        ctype = 5
    return dict(par=pbest, residual=normF_best / math.sqrt(n), feval=fcnt,
                iter=it, convergence=ctype)


# ----------------------------------------------- BB 2009.9-1 BBsolve (R)

def bbsolve(par, fn, method=(2, 3, 1), Ms=(50, 10), NMs=(True, False),
            maxit=1500, tol=1e-7, triter=10):
    """expand.grid(method, M, NM): method varies fastest, then M, then NM."""
    combos = [(m, Mv, nm) for nm in NMs for Mv in Ms for m in method]
    best = None
    best_value = INF
    for m, Mv, nm in combos:
        try:
            temp = dfsane(par, fn, m, Mv, maxit=maxit, tol=tol,
                          noimp=min(100, 5 * Mv), NM=nm, triter=triter)
        except (RError, LineSearchFailure):
            continue
        if temp["convergence"] == 0:
            best = temp
            break
        if temp["residual"] < best_value:
            best = temp
            best_value = temp["residual"]
    if best is None:
        raise RError("no BBsolve try produced a result")
    return best


def multistart_solve_converged(p0, fn):
    """multiStart(par = p0, fn, action = 'solve')$converged."""
    converged = []
    for row in p0:
        try:
            ans = bbsolve(row, fn)
        except RError:
            converged.append(False)
            continue
        converged.append(ans["convergence"] == 0)
    return converged


def registered_run():
    rng = set_seed_r(1234)
    u = runif(rng, 900)
    # matrix(runif(900), 300, 3) fills column-major
    p0 = [[u[k], u[300 + k], u[600 + k]] for k in range(300)]
    conv = multistart_solve_converged(p0, hdp)
    return sum(1 for c in conv if c)


def self_test():
    ok = True
    ref = standard_mt_first_output(5489)
    print("MT19937 reference init_genrand(5489) first output: %d (expect 3499211612)" % round(ref))
    ok &= round(ref) == 3499211612
    r = runif(set_seed_r(1234), 3)
    print("R set.seed(1234) runif(3): %s (expect 0.1137034 0.6222994 0.6092747 from R)" %
          ["%.7f" % v for v in r])
    return ok


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(0 if self_test() else 1)
    count = registered_run()
    print("sum(ans$conv) = %d (registered claim 284, tolerance 281..287)" % count)
