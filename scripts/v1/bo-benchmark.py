import argparse
import atexit
import logging
import pathlib
import signal
import sys
import warnings
from concurrent.futures import ProcessPoolExecutor, as_completed
from functools import partial
from multiprocessing import shared_memory

import numpy as np
import pandas as pd
from bo import EI, LCB, PI, simulate_bo

warnings.filterwarnings("ignore")

parser = argparse.ArgumentParser()
parser.add_argument("X", type=pathlib.Path, help="Predictor csv file.")
parser.add_argument("ell", type=pathlib.Path, help="Loss csv file.")
parser.add_argument("--acquisition", choices=["EI", "LCB", "PI"])
parser.add_argument("--kappa", type=float, help="LCB kappa value.")
parser.add_argument(
    "--n-estimators",
    type=int,
    required=True,
    help="Number of estimators for Random Forest.",
)
parser.add_argument(
    "--n-sim", type=int, required=True, help="Number of Monte Carlo simulations."
)
parser.add_argument(
    "--n-jobs",
    type=int,
    default=1,
    help="Number of jobs to run in parallel.",
)
parser.add_argument("-o", "--out", type=pathlib.Path, help="Output npy file.")
args = parser.parse_args()

# Setup logging
logging.basicConfig(
    level=getattr(logging, "INFO"),
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()],
)
logger = logging.getLogger(__name__)

df = pd.read_csv(args.X).drop(columns=["name", "cosine_of_contact_angle"])
df["slurry"] = df["slurry"].astype("category").cat.codes
X = df.to_numpy()  # shape ~ (530, 7)
ell = pd.read_csv(args.ell)["shape_loss"]  # shape ~ (530,)

# Create shared memory for large arrays
X_shm = shared_memory.SharedMemory(create=True, size=X.nbytes)
X_shared = np.ndarray(X.shape, dtype=X.dtype, buffer=X_shm.buf)
X_shared[:] = X[:]

ell_shm = shared_memory.SharedMemory(create=True, size=ell.values.nbytes)
ell_shared = np.ndarray(ell.shape, dtype=ell.dtype, buffer=ell_shm.buf)
ell_shared[:] = ell.values[:]

if args.acquisition == "EI":
    acquisition_function = EI
elif args.acquisition == "LCB":
    acquisition_function = partial(LCB, kappa=args.kappa)
elif args.acquisition == "PI":
    acquisition_function = PI

N_SIM = args.n_sim
rng = np.random.default_rng(0)
idxs0s = [rng.choice(len(X), size=2, replace=False) for _ in range(N_SIM)]


def init_worker(
    X_shm_name,
    X_shape,
    X_dtype,
    ell_shm_name,
    ell_shape,
    ell_dtype,
):
    """Initialize worker process with shared data"""
    import threadpoolctl

    threadpoolctl.threadpool_limits(1)

    # Variables to be used within worker processes
    global X_shm_worker, ell_shm_worker, worker_X, worker_ell

    # Attach to shared memory
    X_shm_worker = shared_memory.SharedMemory(name=X_shm_name)
    worker_X = np.ndarray(X_shape, dtype=X_dtype, buffer=X_shm_worker.buf)

    ell_shm_worker = shared_memory.SharedMemory(name=ell_shm_name)
    worker_ell = np.ndarray(ell_shape, dtype=ell_dtype, buffer=ell_shm_worker.buf)


def run_simulation(sim_no, idxs0, n_estimators, acquisition_function):
    """Run a single Monte Carlo simulation with error handling"""
    idxs = np.delete(np.arange(len(worker_X)), idxs0)

    ret = simulate_bo(
        worker_X,
        worker_ell,
        idxs,
        idxs0,
        n_estimators,
        acquisition_function,
    )
    return sim_no, ret


# Prepare results storage
results = [None] * N_SIM


def cleanup_shared_memory():
    """Cleanup function that runs at program exit"""
    try:
        X_shm.close()
        X_shm.unlink()
    except Exception:
        pass

    try:
        ell_shm.close()
        ell_shm.unlink()
    except Exception:
        pass


def signal_handler(futures, signum, frame):
    for future in futures:
        future.cancel()
    cleanup_shared_memory()
    exit(0)


atexit.register(cleanup_shared_memory)

# Use ProcessPoolExecutor with optimized initialization
try:
    with ProcessPoolExecutor(
        max_workers=args.n_jobs,
        initializer=init_worker,
        initargs=(
            X_shm.name,
            X.shape,
            X.dtype,
            ell_shm.name,
            ell.shape,
            ell.dtype,
        ),
    ) as executor:
        logger.info(f"{args.out}: Initializing simulations...")
        futures = [
            executor.submit(
                run_simulation, sim_no, idxs0, args.n_estimators, acquisition_function
            )
            for sim_no, idxs0 in enumerate(idxs0s)
        ]
        signal.signal(signal.SIGTERM, partial(signal_handler, futures))
        signal.signal(signal.SIGINT, partial(signal_handler, futures))
        signal.signal(signal.SIGQUIT, partial(signal_handler, futures))

        completed = 0
        for future in as_completed(futures):
            sim_no, ret = future.result()
            results[sim_no] = ret
            completed += 1

            logger.info(f"{args.out}: {completed}/{N_SIM}")
    np.save(args.out, np.array(results))

except KeyboardInterrupt:
    for future in futures:
        future.cancel()
    cleanup_shared_memory()
    sys.exit(0)
