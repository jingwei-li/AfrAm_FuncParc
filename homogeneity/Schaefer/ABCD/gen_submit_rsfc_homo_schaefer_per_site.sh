#!/bin/bash

proj_dir='/data/project/AfrAm_FuncParc'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/code/logs/homo_per_site
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD
executable     = /usr/bin/matlab95
transfer_executable   = False
\n"

ls_dir=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD/lists/matched_6bigsites
outdir=$proj_dir/data/homogeneity/Schaefer/ABCD/site_effects/rsfc_homo
for site in "02" "04" "06" "14" "16" "20"; do
    fsLR_ls=$ls_dir/fsLR_raw_conf_matched_subj_100_site${site}_White
    outname=$outdir/raw_conf_matched_subj_100_site${site}_White.mat
    printf "arguments = -singleCompThread -r rsfc_homo_schaefer_per_site(400,'$fsLR_ls','$outname')\n"
    printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).log\n"
    printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).out\n"
    printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).err\n"
    printf "Queue\n\n"
done 