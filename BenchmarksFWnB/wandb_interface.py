import os
import shutil
import socket
import sys
import tempfile
from contextlib import contextmanager

import wandb

from runner import Runner
from utils import Utils

debug = '--debug' in sys.argv
defaults = dict(
    package="Boscia",                                       # FrankWolfe or Boscia
    fw_variant="BPCG",                                          # Variant to use, e.g. Vanilla, BPCG, DICG, Away  
    problem="CubeSimpleInt",                                          # Problem to benchmark, e.g. Spectrahedron, Birkhoff, D-Optimal, SparseReg                          
    build_args="Dict(:n=>50)",          # Arguments to build the problem, e.g. dict(n=100), dict(n=100, rhs=100_000)
    seed=1234,                                                  # Seed for the random number generator
    kwargs="Dict{Symbol, Any}()",         # Keyword arguments 
    time_per_run=20,                                            # Time per run in seconds
    num_runs=1,                                                 # Number of runs to perform
    settings_bnb="",                         # Settings for Boscia solver
    settings_fw="",
    settings_tol="Dict{Symbol, Any}()",
    settings_pp="Dict{Symbol, Any}()",
    settings_heur="Dict{Symbol, Any}()",
    settings_tight="Dict{Symbol, Any}()",
    settings_domain="Dict{Symbol, Any}()",
    settings_mode="Dict{Symbol, Any}()",
) 

if not debug:
    # Set everything to None recursively
    defaults = Utils.fill_dict_with_none(defaults)

# Add the hostname to the defaults
defaults['computer'] = socket.gethostname()

# Configure wandb logging
w = wandb.init(
    config=defaults,
    project='bm-fw-b-000',  # automatically changed in sweep
    entity=None,  # automatically changed in sweep
)
config = wandb.config
config = Utils.update_config_with_default(config, defaults)
config['name'] = w.name

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

