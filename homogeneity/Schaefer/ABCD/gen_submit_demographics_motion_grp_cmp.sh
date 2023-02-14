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
initial_dir    = $proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD
executable     = /usr/bin/matlab95
transfer_executable   = False
\n"

#grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD/lists/subjects_rs_censor_rand300EA.txt
grp1_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD/lists/subjects_rs_censor_matchedWA_ub1.0.txt
#grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD/lists/subjects_rs_censor_rand300AA.txt
grp2_subj_ls=$proj_dir/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD/lists/subjects_rs_censor_matchedAA_ub1.0.txt
ABCD_dir=$proj_dir/data/datasets/inm7_superds/original/abcd/derivatives/abcd-hcp-pipeline
censor_mat=/data/project/parcellate_ABCD_preprocessed/scripts/lists/subjects_rs_censor.mat
demo_csv=$proj_dir/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/acspsw03.txt
hand_csv=$proj_dir/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_ehis01.txt
site_csv=$proj_dir/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_lt01.txt
#outmat=$proj_dir/data/homogeneity/Schaefer/ABCD/demo_motion_cmp_rand300WA300AA.mat
outmat=$proj_dir/data/homogeneity/Schaefer/ABCD/demo_motion_cmp_matchedWAAA_ub1.0.mat
printf "arguments = -singleCompThread -r demographics_motion_grp_cmp('$grp1_subj_ls','$grp2_subj_ls','$ABCD_dir','$censor_mat','$demo_csv','$hand_csv','$site_csv','$outmat')\n"
printf "log       = ${LOGS_DIR}/ABCD.\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/ABCD.\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/ABCD.\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"