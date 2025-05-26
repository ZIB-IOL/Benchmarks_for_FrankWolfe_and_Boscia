import os
import shutil
import socket
import sys
import tempfile
from contextlib import contextmanager
from juliacall import Main as jl

from typing import List, Optional, Tuple
import platform

import wandb

from runner import Runner
from utils import Utils

debug = '--debug' in sys.argv
defaults = dict(
    package="FrankWolfe",                                       # FrankWolfe or Boscia
    fw_variant="BPCG",                                          # Variant to use, e.g. Vanilla, BPCG, DICG, Away  
    problem="Simplex",                                          # Problem to benchmark, e.g. Spectrahedron, Birkhoff, D-Optimal, SparseReg                          
    build_args=dict(),                  # Arguments to build the problem, e.g. dict(n=100), dict(n=100, rhs=100_000)
    seed=1234,                                                  # Seed for the random number generator
    fw_kwargs=dict(),                                           # Keyword arguments to pass to the FrankWolfe variant
    time_per_run=20,                                            # Time per run in seconds
    num_runs=1,                                                 # Number of runs to perform
) 

if not debug:
    # Set everything to None recursively
    defaults = Utils.fill_dict_with_none(defaults)

# Add the hostname to the defaults
defaults['computer'] = socket.gethostname()

# Configure wandb logging
wandb.init(
    config=defaults,
    project='bm-fw-b-000',  # automatically changed in sweep
    entity=None,  # automatically changed in sweep
)
config = wandb.config
config = Utils.update_config_with_default(config, defaults)

@contextmanager
def tempdir():
    path = tempfile.mkdtemp()   # Creates a temporary directory under /tmp, which is automatically cleanup by the script (and by SLURM when on the HTC Cluster)
    try:
        yield path
    finally:
        try:
            shutil.rmtree(path)
            sys.stdout.write(f"Removed temporary directory {path}.\n")
        except IOError:
            sys.stderr.write('Failed to clean up temp dir {}'.format(path))

with tempdir() as tmp_dir:
    runner = Runner(config=config, tmp_dir=tmp_dir, debug=debug)
    runner.run()
    # Close wandb run
    wandb_dir_path = wandb.run.dir
    wandb.join()

    # Delete the local files
    if os.path.exists(wandb_dir_path):
        shutil.rmtree(wandb_dir_path)

# If exists, delete the core dump file from the directory of main.py
if os.path.exists('core'):
    os.remove('core')

