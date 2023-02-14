#!/bin/bash

proj_dir='/data/project/AfrAm_FuncParc'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CPUS='1'
RAM='5G'
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
data_dir=$proj_dir/data/datasets/inm7_superds/processed/rs_fix/GSP
outmat=$proj_dir/data/homogeneity/Schaefer/GSP/ROI2ROI_RSFC_rand500WA500Other.mat
printf "arguments = -singleCompThread -r ROI2ROI_RSFC('$subj_ls','$data_dir','$outmat')\n"
printf "log       = ${LOGS_DIR}/ROI2ROI_RSFC.\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/ROI2ROI_RSFC.\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/ROI2ROI_RSFC.\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"