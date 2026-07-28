import numpy as np
from scipy.stats import norm
from sklearn.ensemble import RandomForestRegressor

__all__ = [
    "rf_predict",
    "EI",
    "LCB",
    "PI",
    "simulate_bo",
]


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


def simulate_bo(X, ell, idxs, idxs0, n_estimators, acquisition_function):
    rf = RandomForestRegressor(n_estimators=n_estimators)

    for _ in range(len(idxs)):
        X_train = X[idxs0]
        y_train = ell[idxs0]
        rf.fit(X_train, y_train)

        X_pool = X[idxs]
        y_best = np.min(y_train)

        acq_values = acquisition_function(X_pool, rf, y_best)
        next_idx_in_pool = np.argmax(acq_values)

        next_idx = idxs[next_idx_in_pool]
        idxs0 = np.append(idxs0, next_idx)
        idxs = np.delete(idxs, next_idx_in_pool)
    return idxs0
