#!/bin/bash

### EXPERIMENT configurations
sweep_ids=('wandb agent dkuzinow/bm-fw-b-000/jsxk3ep8') # Sweep IDs
job_name="BenchmarksFWnB-Test" # Job name for tracking
git_repo_name="Benchmarks_for_FrankWolfe_and_Boscia/BenchmarksFWnB"
branch="wandb"

### SLURM configurations
max_time="0-12" # Maximum time in days-hours format
partitions=("small")
submit_all_at_once=true # Submit all jobs at once
num_experiments=2 # Number of experiments per sweep, adjust as needed
max_concurrent_runs=1380 # Maximum number of concurrent running jobs
mem="64G"
constraint="Gold6338"  # Constrains to htc-cmp[101-148]


### CODE
partition_list=$(IFS=,; echo "${partitions[*]}")
git_repo_path="/home/htc/$USER/git-repos/$git_repo_name"

# Iterate over the array and remove the "wandb agent " prefix if present
for i in "${!sweep_ids[@]}"; do
    sweep_ids[$i]=${sweep_ids[$i]#wandb agent }
done

# Function to check current running jobs
check_running_jobs() {
    current_running=$(squeue -u $USER -t RUNNING,PENDING -p $partition_list | grep $job_name | wc -l)
    if [[ $current_running -lt $max_concurrent_runs ]]; then
        return 0 # Okay to submit
    else
        return 1 # Wait needed
    fi
}

# Submit jobs
for sweep_id in "${sweep_ids[@]}"; do
    echo "Starting sweep $sweep_id."
    for (( i=1; i<=$num_experiments; i++ )); do
        if [[ $submit_all_at_once == false ]]; then
            while ! check_running_jobs; do
                sleep 5
            done
        fi

        sbatch -p $partition_list --mem=$mem\
                --time=$max_time --job-name=$job_name \
                --constraint=$constraint cpu_runner.sh $git_repo_path $branch $sweep_id
    done
done
