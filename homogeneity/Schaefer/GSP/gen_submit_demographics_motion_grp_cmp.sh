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
initial_dir    = $proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP
executable     = /usr/bin/matlab95
transfer_executable   = False
\n"

#grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists/subject_rfMRI_rand500WA.txt
grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists/subject_rfMRI_matchedWA_ub0.1.txt
#grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists/subject_rfMRI_rand500Other.txt
grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists/subject_rfMRI_matchedOther_ub0.1.txt
data_dir=$proj_dir/data/datasets/inm7_superds/processed/rs_fix/GSP
demo_csv=$proj_dir/data/datasets/GSP_extended_140630.csv
#outmat=$proj_dir/data/homogeneity/Schaefer/GSP/demo_motion_cmp_rand500WA500Other.mat
outmat=$proj_dir/data/homogeneity/Schaefer/GSP/demo_motion_cmp_matchedWAOther_ub0.1.mat
printf "arguments = -singleCompThread -r demographics_motion_grp_cmp('$grp1_subj_ls','$grp2_subj_ls','$data_dir','$demo_csv','$outmat')\n"
printf "log       = ${LOGS_DIR}/GSP.\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/GSP.\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/GSP.\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"