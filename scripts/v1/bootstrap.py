import numpy as np

__all__ = [
    "Top5p",
    "Top5p_RS",
    "EF",
    "AF",
    "bootstrap_median",
]


def Top5p(mc, D_5p):
    _, M = mc.shape
    isin = np.isin(mc, D_5p)
    cumsum = np.cumsum(isin, axis=1)
    ret = cumsum / len(D_5p)

    # Correct the minimal expectation by initial random search
    ret[:, :2] = Top5p_RS(M)[:2]
    ret[:, 2:] = np.clip(ret[:, 2:], Top5p_RS(M)[1], None)
    return ret


def Top5p_RS(N):
    M = 0.05 * N
    P = np.empty(N, dtype=float)
    top = np.empty(N, dtype=float)

    P[0] = 0.05
    top[0] = P[0] / M
    for i in range(1, N):
        P[i] = (M - P[:i].sum()) / (N - i)
        top[i] = P[: i + 1].sum() / M
    return top


def EF(top5p):
    top5p_rs = Top5p_RS(top5p.shape[1])
    return top5p / top5p_rs


def AF(top5p):
    N, M = top5p.shape
    top5p_rs = Top5p_RS(M)
    percents = np.linspace(0, 1, 20)

    i_BO = np.array(
        [np.searchsorted(top5p[i], percents, side="right") for i in range(N)]
    )
    i_RS = np.tile(np.searchsorted(top5p_rs, percents, side="right"), (N, 1))

    ret = np.empty_like(i_BO, dtype=float)
    mask = i_BO == 0
    ret[mask] = 1.0  # Avoid zero division
    ret[~mask] = i_RS[~mask] / i_BO[~mask]
    return ret


def bootstrap_median(X, B, ci, random_state=None):
    N, _ = X.shape
    rng = np.random.default_rng(random_state)
    boot_idx = rng.integers(0, N, size=(B, N))

    boot_samples = X[boot_idx, :]
    boot_medians = np.median(boot_samples, axis=1)
    E_median = boot_medians.mean(axis=0)
    ci_low, ci_high = np.percentile(boot_medians, ci, axis=0)
    return np.stack([E_median, ci_low, ci_high], axis=0)
