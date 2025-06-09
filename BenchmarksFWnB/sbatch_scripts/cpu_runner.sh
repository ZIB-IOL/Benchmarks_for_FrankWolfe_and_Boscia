#!/bin/bash
#SBATCH --output=/home/htc/dkuzinow/SCRATCH/FW-Boscia-showcase/FW-Boscia-showcase_%j.txt
#SBATCH --cpus-per-task=16   # Specify total number of CPUs for the job
# Usage: cpu_runner.sh <git_repo_path> <branch> <sweep_id>
# NOTE: Adjust username in the SBATCH command above, this cannot be dynamically inferred from $USER

git_repo_path=$1
branch=$2
sweep_id=$3

# Switch to the cwd
cd $git_repo_path

# Acquire node information
echo 'Getting node information'
date;hostname;id;pwd

# Setup environment
echo 'Activating virtual environment'
bash
source ~/.bashrc
source .venv/bin/activate
git checkout $branch
which python


# Setup internet access and set environment variables
echo 'Enabling Internet Access'
export https_proxy=http://squid.zib.de:3128
export http_proxy=http://squid.zib.de:3128

echo 'Set the wandb directory variable'
export WANDB_DIR=/home/htc/$USER/SCRATCH


# Setup temporary directory (this avoids the problem that wandb fills up the git repo with 100k files)
if [ -d "/scratch/local" ]; then
  # Create /scratch/local/$USER and /scratch/local/$USER/tmp if they do not exist
  mkdir -p "/scratch/local/$USER/tmp"

  # Set TMPDIR to the temporary directory
  export TMPDIR="/scratch/local/$USER/tmp"
fi

#sleep 5

# Execute the job
srun wandb agent --count 1 $sweep_id 
