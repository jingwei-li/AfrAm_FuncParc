#!/bin/bash

proj_dir='/data/project/AfrAm_FuncParc'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/code/logs/homogeneity
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP-A
executable     = /usr/bin/matlab95
transfer_executable   = False
\n"

ls_dir=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP-A/lists
HCPA_dir=$proj_dir/data/datasets/inm7_superds/original/hcp/hcp_aging
outdir=$proj_dir/data/homogeneity/Schaefer/HCP-A
mkdir -p $outdir
# loop through lists
for race in AA WA; do
    #subj_ls=$ls_dir/subject_rfMRI_rand100${race}.txt
    subj_ls=$ls_dir/subject_rfMRI_matched${race}_ub0.2.txt
    #outname=$outdir/rsfc_homo_400_rand100${race}.mat
    outname=$outdir/rsfc_homo_400_matched${race}_ub0.2.mat
    printf "arguments = -singleCompThread -r rsfc_homo_schaefer(400,'$subj_ls','$HCPA_dir','$outname')\n"
    printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.log\n"
    printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.out\n"
    printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.err\n"
    printf "Queue\n\n"
done