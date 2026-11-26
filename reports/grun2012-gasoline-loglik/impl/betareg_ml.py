# CC0. Maximum likelihood fit of the beta regression
#   yield ~ batch + temp   (logit link for the mean, constant precision phi)
# written from Grun, Kosmidis & Zeileis (2012), section on the gasoline yield
# example, and from the betareg model definition: y ~ Beta(mu*phi, (1-mu)*phi),
# logit(mu) = X beta, phi constant (betareg's default for ~ 1 precision).
# Pure Python (stdlib only), two independent optimisers as an optimiser check:
# BFGS with analytic gradient, and Nelder-Mead from a different start.
import csv
import math
import sys


def load(path):
    rows = []
    with open(path) as f:
        for r in csv.DictReader(f):
            rows.append((float(r["yield"]), r["batch"], float(r["temp"])))
    return rows


def design(rows):
    levels = sorted({b for _, b, _ in rows}, key=int)
    ref = levels[0]
    cols = levels[1:]
    X = []
    for _, b, t in rows:
        x = [1.0] + [1.0 if b == lev else 0.0 for lev in cols] + [t / 100.0]
        X.append(x)
    y = [yy for yy, _, _ in rows]
    return X, y


def loglik(theta, X, y):
    k = len(X[0])
    beta, logphi = theta[:k], theta[k]
    phi = math.exp(logphi)
    ll = 0.0
    for xi, yi in zip(X, y):
        eta = sum(b * v for b, v in zip(beta, xi))
        # mu = inverse logit, computed stably
        mu = 1.0 / (1.0 + math.exp(-eta))
        a = mu * phi
        c = (1.0 - mu) * phi
        ll += (math.lgamma(phi) - math.lgamma(a) - math.lgamma(c)
               + (a - 1.0) * math.log(yi) + (c - 1.0) * math.log(1.0 - yi))
    return ll


def grad(theta, X, y):
    # analytic gradient of loglik (chain rule through the logit and log-phi)
    k = len(X[0])
    beta, logphi = theta[:k], theta[k]
    phi = math.exp(logphi)
    g = [0.0] * (k + 1)
    for xi, yi in zip(X, y):
        eta = sum(b * v for b, v in zip(beta, xi))
        mu = 1.0 / (1.0 + math.exp(-eta))
        a = mu * phi
        c = (1.0 - mu) * phi
        ystar = math.log(yi)
        ystar1 = math.log(1.0 - yi)
        # d/dmu of [-lgamma(mu phi) - lgamma((1-mu) phi)] = -phi*(psi(a) - psi(c))
        dll_dmu = phi * (ystar - ystar1 - _digamma(a) + _digamma(c))
        dmu_deta = mu * (1.0 - mu)
        dll_deta = dll_dmu * dmu_deta
        for j in range(k):
            g[j] += dll_deta * xi[j]
        # d/dphi: psi(phi) - mu psi(a) - (1-mu) psi(c) + mu log y + (1-mu) log(1-y)
        dll_dphi = (_digamma(phi) - mu * _digamma(a) - (1.0 - mu) * _digamma(c)
                    + mu * ystar + (1.0 - mu) * ystar1)
        g[k] += dll_dphi * phi  # chain rule for phi = exp(logphi)
    return g


def _digamma(x):
    # asymptotic series with recurrence shift, accurate to ~1e-12 for x > 0
    r = 0.0
    while x < 6.0:
        r -= 1.0 / x
        x += 1.0
    f = 1.0 / (x * x)
    t = f * (-1.0 / 12 + f * (1.0 / 120 + f * (-1.0 / 252 + f * (1.0 / 240 + f * (-1.0 / 132)))))
    return r + math.log(x) - 0.5 / x + t


def bfgs(f, g, x0, maxit=2000, gtol=1e-9):
    n = len(x0)
    x = list(x0)
    H = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    fx = f(x)
    gx = g(x)
    for _ in range(maxit):
        if max(abs(v) for v in gx) < gtol:
            break
        p = [-sum(H[i][j] * gx[j] for j in range(n)) for i in range(n)]
        slope = sum(pi * gi for pi, gi in zip(p, gx))
        if slope >= 0:  # not descent: reset
            H = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
            p = [-v for v in gx]
            slope = sum(pi * gi for pi, gi in zip(p, gx))
        t = 1.0
        while True:
            xn = [xi + t * pi for xi, pi in zip(x, p)]
            fn = f(xn)
            if fn >= fx + 1e-4 * t * slope or t < 1e-12:
                break
            t *= 0.5
        if not math.isfinite(fn):
            break  # no admissible descent step left: stop at the last valid point
        gn = g(xn)
        s = [a - b for a, b in zip(xn, x)]
        yv = [a - b for a, b in zip(gn, gx)]
        sy = sum(a * b for a, b in zip(s, yv))
        if sy > 1e-12:
            Hy = [sum(H[i][j] * yv[j] for j in range(n)) for i in range(n)]
            yHy = sum(a * b for a, b in zip(yv, Hy))
            for i in range(n):
                for j in range(n):
                    H[i][j] += ((sy + yHy) * s[i] * s[j]) / (sy * sy) \
                        - (Hy[i] * s[j] + s[i] * Hy[j]) / sy
        x, fx, gx = xn, fn, gn
    return x, fx


def nelder_mead(f, x0, step=0.1, maxit=40000, tol=1e-12):
    n = len(x0)
    simplex = [list(x0)]
    for i in range(n):
        v = list(x0)
        v[i] += step
        simplex.append(v)
    vals = [f(v) for v in simplex]
    for _ in range(maxit):
        order = sorted(range(n + 1), key=lambda i: vals[i])
        simplex = [simplex[i] for i in order]
        vals = [vals[i] for i in order]
        if abs(vals[-1] - vals[0]) < tol:
            break
        cen = [sum(simplex[i][j] for i in range(n)) / n for j in range(n)]
        xr = [c + (c - w) for c, w in zip(cen, simplex[-1])]
        fr = f(xr)
        if fr < vals[0]:
            xe = [c + 2 * (c - w) for c, w in zip(cen, simplex[-1])]
            fe = f(xe)
            if fe < fr:
                simplex[-1], vals[-1] = xe, fe
            else:
                simplex[-1], vals[-1] = xr, fr
        elif fr < vals[-2]:
            simplex[-1], vals[-1] = xr, fr
        else:
            xc = [c + 0.5 * (w - c) for c, w in zip(cen, simplex[-1])]
            fc = f(xc)
            if fc < vals[-1]:
                simplex[-1], vals[-1] = xc, fc
            else:
                for i in range(1, n + 1):
                    simplex[i] = [b + 0.5 * (a - b) for a, b in zip(simplex[i], simplex[0])]
                    vals[i] = f(simplex[i])
    i = min(range(n + 1), key=lambda k: vals[k])
    return simplex[i], vals[i]


def main(path):
    rows = load(path)
    X, y = design(rows)
    k = len(X[0])
    print("n =", len(y), " parameters =", k + 1)
    def f(th):
        # outside the support (mu or phi underflowing) the line search must back off
        try:
            v = -loglik(th, X, y)
        except (ValueError, OverflowError):
            return float("inf")
        return v if math.isfinite(v) else float("inf")
    g = lambda th: [-v for v in grad(th, X, y)]
    # start: intercept at logit of mean, phi from the sample variance
    mean = sum(y) / len(y)
    var = sum((v - mean) ** 2 for v in y) / (len(y) - 1)
    phi0 = mean * (1 - mean) / var - 1
    start = [math.log(mean / (1 - mean))] + [0.0] * (k - 1) + [math.log(phi0)]
    # gradient check against finite differences at the start
    h = 1e-6
    fd = []
    for j in range(k + 1):
        tp = list(start); tp[j] += h
        tm = list(start); tm[j] -= h
        fd.append((loglik(tp, X, y) - loglik(tm, X, y)) / (2 * h))
    an = grad(start, X, y)
    print("max |analytic - finite-difference| gradient at start: %.3g" % max(abs(a - b) for a, b in zip(an, fd)))
    th1, f1 = bfgs(f, g, start)
    print("BFGS          logLik = %.8f" % (-f1))
    th2, f2 = nelder_mead(f, th1, step=0.05)
    print("Nelder-Mead   logLik = %.8f (restarted from BFGS optimum)" % (-f2))
    th3, f3 = nelder_mead(f, start, step=0.5, maxit=200000)
    print("Nelder-Mead   logLik = %.8f (from the moment start)" % (-f3))
    best = min([(f1, th1), (f2, th2), (f3, th3)], key=lambda t: t[0])
    print("best logLik = %.8f" % (-best[0]))
    # stationarity check: the gradient of the log-likelihood should vanish at the optimum
    print("max |gradient| at best = %.3g" % max(abs(v) for v in g(best[1])))
    print("phi = %.6f" % math.exp(best[1][-1]))
    print("beta =", ["%.6f" % v for v in best[1][:-1]])


if __name__ == "__main__":
    main(sys.argv[1])
