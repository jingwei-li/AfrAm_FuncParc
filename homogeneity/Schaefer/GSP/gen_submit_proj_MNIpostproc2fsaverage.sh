#!/bin/bash

proj_dir='/data/project/AfrAm_FuncParc'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CPUS='1'
RAM='3G'
LOGS_DIR=$proj_dir/code/logs/GSP_postproc
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP
executable     = /usr/bin/matlab95
transfer_executable   = False
\n"

subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists/subject_rfMRI_rand500WA500Other.txt
MNI_dir=$proj_dir/data/datasets/GSP_postproc/reg_mt_gs_wm_csf
for s in $(cat $subj_ls); do
    if [ ! -f $MNI_dir/surf/rh.${s}_ses01_postproc.nii.gz ]; then
        printf "arguments = -singleCompThread -r proj_MNIpostproc2fsaverage_persub('$s','$MNI_dir')\n"
        printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.log\n"
        printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.out\n"
        printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.err\n"
        printf "Queue\n\n"
    fi
done