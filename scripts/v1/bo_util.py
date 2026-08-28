import logging

import numpy as np
from scipy.stats import norm
from sklearn.ensemble import RandomForestRegressor

__all__ = [
    "rf_predict",
    "unique_pool",
    "mean_loss_by_x",
    "EI",
    "LCB",
    "PI",
    "bo",
    "simulate_bo",
]


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def unique_pool(X):
    """Return the unique candidate pool and each profile's pool index."""
    X = np.asarray(X)
    if X.ndim != 2:
        raise ValueError("X must be a two-dimensional array")
    return np.unique(X, axis=0, return_inverse=True)


def mean_loss_by_x(ell, profile_to_x, n_x=None):
    """Aggregate profile losses into the mean objective for each unique x."""
    ell = np.asarray(ell)
    profile_to_x = np.asarray(profile_to_x)
    if ell.ndim != 1 or profile_to_x.ndim != 1:
        raise ValueError("ell and profile_to_x must be one-dimensional arrays")
    if len(ell) != len(profile_to_x):
        raise ValueError("ell and profile_to_x must have the same length")
    if len(ell) == 0:
        raise ValueError("ell must contain at least one profile loss")
    if np.any(profile_to_x < 0):
        raise ValueError("profile_to_x must contain non-negative indices")

    inferred_n_x = int(profile_to_x.max()) + 1
    if n_x is None:
        n_x = inferred_n_x
    if n_x < inferred_n_x:
        raise ValueError("n_x is smaller than the largest profile_to_x index")

    counts = np.bincount(profile_to_x, minlength=n_x)
    if np.any(counts == 0):
        raise ValueError("every x must have at least one profile loss")
    sums = np.bincount(profile_to_x, weights=ell, minlength=n_x)
    return sums / counts


def rf_predict(X, rf):
    # https://github.com/PV-Lab/Benchmarking
    tree_pred = np.array([tree.predict(X) for tree in rf.estimators_])
    mean = np.mean(tree_pred, axis=0)
    std = np.std(tree_pred, axis=0)
    return mean, std


def EI(X, gp, y_best):
    mu, sigma = rf_predict(X, gp)
    with np.errstate(divide="warn"):
        improvement = y_best - mu
        Z = improvement / sigma
        ei = improvement * norm.cdf(Z) + sigma * norm.pdf(Z)
        ei[sigma == 0.0] = 0.0
    return ei


def LCB(X, gp, y_best, kappa):
    mu, sigma = rf_predict(X, gp)
    return mu - kappa * sigma


def PI(X, gp, y_best):
    mu, sigma = rf_predict(X, gp)
    with np.errstate(divide="warn"):
        improvement = y_best - mu
        Z = improvement / sigma
        pi = norm.cdf(Z)
        pi[sigma == 0.0] = 0.0
    return pi


def bo(X, ell, sample_idxs, n_iter, n_estimators=300, random_state=0):
    sample_idx = np.array(sample_idxs)
    rf = RandomForestRegressor(n_estimators=n_estimators, random_state=random_state)
    for iteration in range(n_iter):
        X_train = X[sample_idx]
        y_train = ell[sample_idx]
        X_pool = np.delete(X, sample_idx, axis=0)
        rf.fit(X_train, y_train)

        y_best = np.min(y_train)
        acquisition_values = EI(X_pool, rf, y_best)

        next_idx = np.delete(np.arange(len(X)), sample_idx)[
            np.argmax(acquisition_values)
        ]
        sample_idx = np.append(sample_idx, next_idx)
        logger.info(
            "BO iteration %d/%d: selected index %d (best objective: %s)",
            iteration + 1,
            n_iter,
            next_idx,
            y_best,
        )
    return sample_idx


def simulate_bo(
    X,
    ell,
    profile_to_x,
    idxs,
    idxs0,
    n_estimators,
    acquisition_function,
):
    """Select unique x values while revealing all profile losses at each x."""
    rf = RandomForestRegressor(n_estimators=n_estimators)
    observed_x = np.zeros(len(X), dtype=bool)
    observed_x[idxs0] = True

    for _ in range(len(idxs)):
        observed_profiles = observed_x[profile_to_x]
        X_train = X[profile_to_x[observed_profiles]]
        y_train = ell[observed_profiles]
        rf.fit(X_train, y_train)

        X_pool = X[idxs]
        y_best = np.min(y_train)

        acq_values = acquisition_function(X_pool, rf, y_best)
        next_idx_in_pool = np.argmax(acq_values)

        next_idx = idxs[next_idx_in_pool]
        idxs0 = np.append(idxs0, next_idx)
        observed_x[next_idx] = True
        idxs = np.delete(idxs, next_idx_in_pool)
    return idxs0
