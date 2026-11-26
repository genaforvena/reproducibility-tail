# CC0 (public domain dedication). Reimplementation by the rerun mind.
#
# Pseudo-arclength continuation of an equilibrium branch of the model in
# hopf_search.py, in the input I (nM). Follows folds (saddle-nodes) and records
# the eigenvalues at every step, so Hopf points (complex pair crossing the
# imaginary axis) are located on the branch, not on whichever attractor a
# time integration happens to settle on (the model is multistable and
# oscillatory near the Hopf point).
#
# Usage: python3 continue_branch.py PATH/TO/network.mat {full|qssa} START_I_nM [I_max] [ds] [+1|-1]
import sys
import numpy as np
import hopf_search as h

SX = 100.0  # scale for concentrations (nM) in the continuation variable


def F(u, q, f, n):
    # u = [x/SX (n), I (nM)] -> residual of equilibrium equations, scaled
    x = u[:n] * SX
    I = u[n]
    return f(x, I, q) * 1e3


def jac_aug(u, q, f, n):
    J = np.zeros((n, n + 1))
    for j in range(n + 1):
        h_ = 1e-7 * (abs(u[j]) + 1.0)
        up, um = u.copy(), u.copy()
        up[j] += h_
        um[j] -= h_
        J[:, j] = (F(up, q, f, n) - F(um, q, f, n)) / (2 * h_)
    return J


def tangent(u, q, f, n, t_prev):
    J = jac_aug(u, q, f, n)
    A = np.vstack([J, t_prev[None, :]])
    rhs = np.zeros(n + 1)
    rhs[-1] = 1.0
    t = np.linalg.solve(A, rhs)
    t /= np.linalg.norm(t)
    if np.dot(t, t_prev) < 0:
        t = -t
    return t


def correct(u_pred, t, q, f, n, u_ref):
    u = u_pred.copy()
    for _ in range(50):
        r = F(u, q, f, n)
        c = np.dot(t, u - u_pred)
        if np.max(np.abs(r)) < 1e-10 and abs(c) < 1e-10:
            return u, True
        J = jac_aug(u, q, f, n)
        A = np.vstack([J, t[None, :]])
        du = np.linalg.solve(A, -np.concatenate([r, [c]]))
        u = u + du
    return u, False


def eig_at(u, q, f, n):
    x = u[:n] * SX
    I = u[n]
    J = h.jac(f, x, I, q)
    return np.linalg.eigvals(J), x, I


def main():
    path, model = sys.argv[1], sys.argv[2]
    I0 = float(sys.argv[3])
    Imax = float(sys.argv[4]) if len(sys.argv) > 4 else 12.0
    ds = float(sys.argv[5]) if len(sys.argv) > 5 else 0.005
    direction = float(sys.argv[6]) if len(sys.argv) > 6 else 1.0  # +1: start by increasing I
    q = h.make_params(path)
    f = {"full": h.f_full, "qssa": h.f_qssa}[model]
    n = 12 if model == "full" else 4

    # starting equilibrium: relax from the fig5 initial state at input I0, then polish
    x0 = np.zeros(n)
    x0[:4] = [50.0, 50.0, 0.0, 0.0]
    x, ok = h.track(f, x0, I0, q, T=3e5)
    if not ok:
        print("could not start from an equilibrium at", I0)
        return
    u = np.concatenate([x / SX, [I0]])
    t_prev = np.zeros(n + 1)
    t_prev[-1] = 1.0
    t = tangent(u, q, f, n, t_prev)
    if direction < 0:
        t = -t
    rows, events = [], []
    prev = None
    for step in range(200000):
        u_pred = u + ds * t
        u_new, ok = correct(u_pred, t, q, f, n, u)
        if not ok or np.max(np.abs(u_new[:n] * SX)) > 1e4:
            print(f"continuation stopped at step {step}, I={u[n]:.4f} (corrector failed or left bounds)")
            break
        t_new = tangent(u_new, q, f, n, t)
        ev, x_cur, I_cur = eig_at(u_new, q, f, n)
        k = int(np.argmax(ev.real))
        lam = ev[k]
        rows.append((I_cur, lam.real, lam.imag, x_cur[0], x_cur[1], x_cur[2], x_cur[3]))
        if prev is not None and np.sign(prev[1]) != np.sign(lam.real):
            kind = "HOPF" if abs(lam.imag) > 1e-9 else "FOLD"
            events.append((kind, prev[0], I_cur, prev[1], lam.real, lam.imag, abs(lam.imag)))
            print(f"{kind} crossing between I={prev[0]:.5f} and {I_cur:.5f} nM; Re {prev[1]:.3e} -> {lam.real:.3e}; Im={lam.imag:.4e}")
        prev = (I_cur, lam.real, lam.imag)
        u, t = u_new, t_new
        if I_cur > Imax or I_cur < -0.05:
            print(f"reached input bound at I={I_cur:.4f}")
            break
    np.savetxt(f"branch_{model}_I{I0:g}_{'up' if direction > 0 else 'down'}.csv", np.array(rows), delimiter=",",
               header="I_nM,Re_lambda_max,Im_lambda,R1,R2,R3,R4", comments="")
    print(f"{len(rows)} points; events: {[e[0] for e in events]}")


if __name__ == "__main__":
    main()
