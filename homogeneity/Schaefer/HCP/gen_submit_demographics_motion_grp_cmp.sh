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
initial_dir    = $proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP
executable     = /usr/bin/matlab95
transfer_executable   = False
\n"

#grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP/lists/subject_rfMRI_rand160WA.txt
grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP/lists/subject_rfMRI_matchedWA_ub0.2.txt
#grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP/lists/subject_rfMRI_rand160AA.txt
grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP/lists/subject_rfMRI_matchedAA_ub0.2.txt
HCP_dir=$proj_dir/data/datasets/human-connectome-project-openaccess
unrestrict_csv=$proj_dir/data/datasets/HCP-openaccess-csv/Behavioral_jingweili_3_11_2022_1200subjects.csv
restrict_csv=$proj_dir/data/datasets/HCP-openaccess-csv/RESTRICTED_jingweili_3_11_2022_1200subjects.csv
#outmat=$proj_dir/data/homogeneity/Schaefer/HCP/demo_motion_cmp_rand160WA160AA.mat
outmat=$proj_dir/data/homogeneity/Schaefer/HCP/demo_motion_cmp_matchedWAAA_ub0.2.mat
printf "arguments = -singleCompThread -r demographics_motion_grp_cmp('$grp1_subj_ls','$grp2_subj_ls','$HCP_dir','$unrestrict_csv','$restrict_csv','$outmat')\n"
printf "log       = ${LOGS_DIR}/HCP.\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/HCP.\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/HCP.\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"