# CC0 (public domain dedication). Independent cross-check by the rerun mind.
#
# Time-domain check of the Hopf input found by continue_branch.py, using only the
# full ODE (no Jacobian, no eigenvalues): perturb the equilibrium at an input just
# below and just above the Hopf value and integrate. Below: the perturbation should
# decay. Above: it should grow into a sustained oscillation whose period is compared
# with 2*pi/omega from the eigenvalue calculation.
#
# Usage: python3 check_time_domain.py PATH/TO/network.mat I_below_nM I_above_nM [T_s]
import sys
import numpy as np
import hopf_search as h


def steady_guess(R, I, q):
    # mRNA steady state from the protein values (full_ode.m mRNA equations)
    N, ka, kr = q["N"], q["k_a"], q["k_r"]
    A = h.Ha(I, ka, N)
    h1, h2, h3, h4 = (h.Hr(R[i], kr, N) for i in range(4))
    b, P, dm = q["beta"], q["P_tc"], q["delta_m"]
    m = np.array([b*A*h2, b*A*h2, b*A*h4, b*A*h4, P*h3, P*h3*h4, P*h1, P*h1*h2]) / dm
    return np.concatenate([R, m])


def equilibrium(I, q, R_guess):
    x = steady_guess(R_guess, I, q)
    x, ok = h.newton(h.f_full, x, I, q)
    return x, ok


def run(I, q, T, dt=10.0, kick=1e-3):
    x_eq, ok = equilibrium(I, q, np.array([8.0, 5.0, 13.0, 4.0]))
    if not ok:
        return None
    x = x_eq.copy()
    x[0] += kick * x_eq[0]  # small relative kick to R1
    t, out = 0.0, []
    nsteps = int(T / dt)
    for i in range(nsteps):
        k1 = h.f_full(x, I, q)
        k2 = h.f_full(x + dt/2*k1, I, q)
        k3 = h.f_full(x + dt/2*k2, I, q)
        k4 = h.f_full(x + dt*k3, I, q)
        x = x + dt/6*(k1 + 2*k2 + 2*k3 + k4)
        t += dt
        out.append(x[0] - x_eq[0])
    return np.array(out), x_eq


def peak_period(sig, dt):
    # times of upward zero crossings of the deviation, after the first half
    s = sig[len(sig)//2:]
    idx = np.where((s[:-1] < 0) & (s[1:] >= 0))[0]
    if len(idx) < 3:
        return None, 0.0
    periods = np.diff(idx) * dt
    return float(np.median(periods[-3:])), float(np.max(np.abs(s[-len(s)//4:])))


def main():
    path = sys.argv[1]
    Ib, Ia = float(sys.argv[2]), float(sys.argv[3])
    T = float(sys.argv[4]) if len(sys.argv) > 4 else 1.5e6
    q = h.make_params(path)
    for label, I in (("below", Ib), ("above", Ia)):
        res = run(I, q, T)
        if res is None:
            print(f"{label} I={I}: equilibrium Newton failed")
            continue
        sig, x_eq = res
        per, amp_end = peak_period(sig, 10.0)
        tail = np.max(np.abs(sig[-len(sig)//10:]))
        print(f"{label} I={I} nM: equilibrium R1={x_eq[0]:.3f} nM; |deviation| in last 10% = {tail:.3e} nM; "
              f"period from zero-crossings = {per if per is None else f'{per:.4e} s'}")


if __name__ == "__main__":
    main()
