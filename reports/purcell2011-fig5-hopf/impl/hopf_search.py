# CC0 (public domain dedication). Reimplementation by the rerun mind.
#
# Written from the model description in the replication repo (src/full_ode.m,
# src/qssa.m, src/run_experiment.m) and its parameters (src/parameters/network.mat),
# as a stand-in for the bifurcation calculation the pinned artifact lacks.
# Basis: reimplemented. Nothing here is tuned: all numbers come from network.mat.
#
# Method: continuation of an equilibrium of the chosen model in the input I (nM),
# starting from a long time integration at I = 0, Newton-polished at each step.
# Hopf point = input where a complex-conjugate eigenvalue pair of the Jacobian
# crosses the imaginary axis (real part changes sign with Im != 0), refined by
# bisection. Fold = real eigenvalue crossing zero (reported for cross-checking).
#
# Usage: python3 hopf_search.py PATH/TO/network.mat {full|qssa} [I_max_nM] [step_nM]
import sys
import numpy as np

S = 1e9  # molar -> nanomolar; everything below is in nM and seconds


def read_scalars(path):
    vals, name = {}, None
    for raw in open(path):
        line = raw.strip()
        if line.startswith("# name:"):
            name = line.split(":", 1)[1].strip()
        elif name and line and not line.startswith("#"):
            vals[name] = float(line)
            name = None
    return vals


def make_params(path):
    p = read_scalars(path)
    q = dict(
        k_tl=p["k_tl"], delta_m=p["delta_m"], delta_x=p["delta_x"], N=p["N"],
        k_a=p["k_a"] * S, k_r=p["k_r"] * S, beta=p["beta"] * S, P_tc=p["P_tc"] * S,
    )
    q["alpha"] = q["k_tl"] * q["beta"] / q["delta_m"]   # as qssa/run_experiment.m, nM/s
    q["gamma"] = q["k_tl"] * q["P_tc"] / q["delta_m"]
    return q


def Ha(x, k, N):
    xn = np.power(np.maximum(x, 0.0), N)
    return xn / (k ** N + xn)


def Hr(x, k, N):
    return 1.0 / (1.0 + np.power(np.maximum(x, 0.0), N) / k ** N)


def f_full(x, I, q):
    # state: R1..R4 (proteins), m1..m8 (mRNAs), order as full_ode.m
    N, ka, kr = q["N"], q["k_a"], q["k_r"]
    R, m = x[:4], x[4:]
    A = Ha(I, ka, N)
    h1, h2, h3, h4 = (Hr(R[i], kr, N) for i in range(4))
    b, P, dm = q["beta"], q["P_tc"], q["delta_m"]
    dmv = np.array([
        b * A * h2 - dm * m[0],          # R1P1
        b * A * h2 - dm * m[1],          # R4P1
        b * A * h4 - dm * m[2],          # R2P2
        b * A * h4 - dm * m[3],          # R3P2
        P * h3 - dm * m[4],              # R1P3
        P * h3 * h4 - dm * m[5],         # R2P4
        P * h1 - dm * m[6],              # R3P5
        P * h1 * h2 - dm * m[7],         # R4P6
    ])
    kt, dx = q["k_tl"], q["delta_x"]
    dR = np.array([
        kt * (m[0] + m[4]) - dx * R[0],
        kt * (m[2] + m[5]) - dx * R[1],
        kt * (m[3] + m[6]) - dx * R[2],
        kt * (m[1] + m[7]) - dx * R[3],
    ])
    return np.concatenate([dR, dmv])


def f_qssa(x, I, q):
    N, ka, kr = q["N"], q["k_a"], q["k_r"]
    R = x
    A = Ha(I, ka, N)
    h1, h2, h3, h4 = (Hr(R[i], kr, N) for i in range(4))
    a, g, dx = q["alpha"], q["gamma"], q["delta_x"]
    return np.array([
        a * A * h2 + g * h3 - dx * R[0],
        a * A * h4 + g * h3 * h4 - dx * R[1],
        a * A * h4 + g * h1 - dx * R[2],
        a * A * h2 + g * h1 * h2 - dx * R[3],
    ])


def jac(f, x, I, q):
    n = len(x)
    J = np.zeros((n, n))
    for j in range(n):
        h = 1e-6 * (abs(x[j]) + 1.0)
        xp, xm = x.copy(), x.copy()
        xp[j] += h
        xm[j] -= h
        J[:, j] = (f(xp, I, q) - f(xm, I, q)) / (2 * h)
    return J


def track(f, x, I, q, T=3e4):
    # relax onto the attractor from the previous input's state, then Newton-polish
    x = settle(f, x, I, q, T=T)
    return newton(f, x, I, q)


def settle(f, x, I, q, T=3e5, dt=10.0):
    # RK4 time integration to reach a stable equilibrium (used only at start)
    t = 0.0
    while t < T:
        k1 = f(x, I, q)
        k2 = f(x + dt / 2 * k1, I, q)
        k3 = f(x + dt / 2 * k2, I, q)
        k4 = f(x + dt * k3, I, q)
        x = x + dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        t += dt
    return x


def newton(f, x, I, q, maxit=60):
    for _ in range(maxit):
        r = f(x, I, q)
        if np.max(np.abs(r)) < 1e-9 * max(1.0, float(np.max(np.abs(x)))):
            return x, True
        J = jac(f, x, I, q)
        try:
            dx = np.linalg.solve(J, -r)
        except np.linalg.LinAlgError:
            return x, False
        x = x + dx
        x = np.maximum(x, 0.0)
    r = f(x, I, q)
    return x, bool(np.max(np.abs(r)) < 1e-7)


def spectrum(f, x, I, q):
    ev = np.linalg.eigvals(jac(f, x, I, q))
    k = int(np.argmax(ev.real))
    return ev, ev[k]


def main():
    path, model = sys.argv[1], sys.argv[2]
    imax = float(sys.argv[3]) if len(sys.argv) > 3 else 12.0
    step = float(sys.argv[4]) if len(sys.argv) > 4 else 0.01
    q = make_params(path)
    f = {"full": f_full, "qssa": f_qssa}[model]
    n = 12 if model == "full" else 4
    x0 = np.zeros(n)
    x0[:4] = [50.0, 50.0, 0.0, 0.0]  # initial R1..R4 in nM, as in fig5.mat (R1=R2=50 nM)
    I = 0.0
    x, ok = track(f, x0, I, q, T=3e5)
    print(f"model={model} params N={q['N']} k_a={q['k_a']} nM k_r={q['k_r']} nM beta={q['beta']} P_tc={q['P_tc']}")
    print(f"I=0 settled ok={ok} R={np.round(x[:4], 4).tolist()}")

    prev_g, prev_I, prev_x = None, None, None
    fold, hopf = None, None
    rows = []
    for I in np.arange(0.0, imax + step / 2, step):
        x_new, ok = track(f, x, I, q)
        if not ok:
            print(f"I={I:.3f} equilibrium not reached; stopping continuation")
            break
        x = x_new
        ev, lam = spectrum(f, x, I, q)
        rows.append((I, lam.real, lam.imag, x[0]))
        if prev_g is not None and np.sign(prev_g) != np.sign(lam.real):
            kind = "complex" if abs(lam.imag) > 1e-12 else "real"
            if kind == "complex" and hopf is None:
                hopf = (prev_I, I, prev_x.copy(), x.copy(), prev_g)
            if kind == "real" and fold is None:
                fold = (prev_I, I)
        prev_g, prev_I, prev_x = lam.real, I, x.copy()

    def refine(bracket):
        lo, hi, x_lo, x_hi, g_lo = bracket
        x_cur = x_lo
        for _ in range(40):
            mid = 0.5 * (lo + hi)
            x_m, ok = track(f, x_cur, mid, q)
            if not ok:
                break
            _, lam_m = spectrum(f, x_m, mid, q)
            if np.sign(lam_m.real) == np.sign(g_lo):
                lo, x_cur = mid, x_m
            else:
                hi = mid
            if hi - lo < 1e-7:
                break
        _, lam_hi = spectrum(f, x_cur, lo, q)
        return 0.5 * (lo + hi), x_cur, lam_hi

    if hopf is not None:
        I_h, x_h, lam_h = refine(hopf)
        ev_h, _ = spectrum(f, x_h, I_h, q)
        omega = abs(lam_h.imag)
        print(f"HOPF I_h = {I_h:.4f} nM  (bracket {hopf[0]:.3f}-{hopf[1]:.3f}); omega={omega:.4e} rad/s, period={2*np.pi/omega:.4e} s")
        print(f"  R1 at Hopf = {x_h[0]:.3f} nM; eigenvalues near axis: {np.round(ev_h[np.argsort(-ev_h.real)][:2], 8).tolist()}")
        # Routh-Hurwitz cross-check on the characteristic polynomial of the Jacobian
        c = np.poly(jac(f, x_h, I_h, q))
        a1, a2, a3, a4 = c[1], c[2], c[3], c[4]
        print(f"  RH cross-check (4x4 Jacobian): a1*a2-a3 = {a1*a2-a3:.3e} (should be ~0), a4 = {a4:.3e}")
    else:
        print("HOPF not found in scanned range")
    if fold is not None:
        print(f"FOLD (real eigenvalue crossing zero) between I={fold[0]:.3f} and {fold[1]:.3f} nM")
    else:
        print("FOLD not found in scanned range along this branch")
    np.savetxt(f"scan_{model}.csv", np.array(rows), delimiter=",", header="I_nM,Re_lambda_max,Im_lambda,R1_nM", comments="")


if __name__ == "__main__":
    main()
