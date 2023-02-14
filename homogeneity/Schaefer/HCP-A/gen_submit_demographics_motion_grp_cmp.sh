#!/bin/bash

proj_dir='/data/project/AfrAm_FuncParc'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/code/logs/demo_motion_cmp
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

#grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP-A/lists/subject_rfMRI_rand100WA.txt
grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP-A/lists/subject_rfMRI_matchedWA_ub0.15.txt
#grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP-A/lists/subject_rfMRI_rand100AA.txt
grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP-A/lists/subject_rfMRI_matchedAA_ub0.15.txt
HCPA_dir=$proj_dir/data/datasets/inm7_superds/original/hcp/hcp_aging
#outmat=$proj_dir/data/homogeneity/Schaefer/HCP-A/demo_motion_cmp_rand100WA100AA.mat
outmat=$proj_dir/data/homogeneity/Schaefer/HCP-A/demo_motion_cmp_matchedWAAA_ub0.15.mat
printf "arguments = -singleCompThread -r demographics_motion_grp_cmp('$grp1_subj_ls','$grp2_subj_ls','$HCPA_dir','$outmat')\n"
printf "log       = ${LOGS_DIR}/HCP-A.\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/HCP-A.\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/HCP-A.\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"