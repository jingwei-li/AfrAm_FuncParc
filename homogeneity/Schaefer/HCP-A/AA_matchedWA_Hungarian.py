import os, argparse, random, subprocess
import pandas as pd
import numpy as np
from scipy.optimize import linear_sum_assignment

def norm_trait(trait_AA_in, trait_WA_in):
    trait_mean = np.mean(np.concatenate((trait_AA_in, trait_WA_in), axis=None))
    trait_std = np.std(np.concatenate((trait_AA_in, trait_WA_in), axis=None))
    trait_AA_out = (trait_AA_in - trait_mean) / trait_std
    trait_WA_out = (trait_WA_in - trait_mean) / trait_std
    return trait_AA_out, trait_WA_out

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--demo_csv', help='The CSV file containing demographic (age, sex, race/ethnicity) information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/hcp/hcp_aging/phenotype/ndar_subject01.txt')
parser.add_argument('--hand_csv', help='The CSV file containing handedness information. (absolute path)',
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/hcp/hcp_aging/phenotype/edinburgh_hand01.txt')
parser.add_argument('--data_dir', help='The local directory of HCP-YA datalad repository.',
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/hcp/hcp_aging')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('--cost_ub', type=float, help='Upper bound of assignment cost', default=1.)
parser.add_argument('--outdir', help='Output directory')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]
    subjects_csv = [line[0:10] for line in subjects]

# read csv files, grab subset of the dataframe that is necessary
df_demo = pd.read_csv(args.demo_csv, delimiter='\t')
df_demo = df_demo[df_demo.src_subject_id.isin(subjects_csv)]
df_demo = df_demo[['src_subject_id', 'race', 'interview_age', 'sex']]

df_hand = pd.read_csv(args.hand_csv, delimiter='\t')
df_hand = df_hand[df_hand.src_subject_id.isin(subjects_csv)]
df_hand = df_hand[['src_subject_id', 'hcp_handedness_score']]

# race
WA = df_demo[df_demo.race == 'White'].src_subject_id.tolist()
AA = df_demo[df_demo.race == 'Black or African American'].src_subject_id.tolist()

# get age, sex, handedness of each subject
age_AA = []
hand_AA = []
sex_AA = []
for i in AA:
    age_AA += df_demo[df_demo.src_subject_id == i].interview_age.tolist()
    sex_AA += df_demo[df_demo.src_subject_id == i].sex.tolist()
    hand_AA += df_hand[df_hand.src_subject_id == i].hcp_handedness_score.tolist()
age_AA = np.asarray(age_AA).astype(float)
sex_AA = [0 if i == 'F' else 1 for i in sex_AA]
hand_AA = np.asarray(hand_AA).astype(float)

age_WA = []
hand_WA = []
sex_WA = []
for i in WA:
    age_WA += df_demo[df_demo.src_subject_id == i].interview_age.tolist()
    sex_WA += df_demo[df_demo.src_subject_id == i].sex.tolist()
    hand_WA += df_hand[df_hand.src_subject_id == i].hcp_handedness_score.tolist()
age_WA = np.asarray(age_WA).astype(float)
sex_WA = [0 if i == 'F' else 1 for i in sex_WA]
hand_WA = np.asarray(hand_WA).astype(float)

# get FD for each subject
WA_new = [s + '_V1_MR' for s in WA]
AA_new = [s + '_V1_MR' for s in AA]
os.chdir(args.data_dir)

FD_AA = np.empty(len(AA))
FD_AA[:] = np.nan
print('Collecting FD from AA')
i = 0
while i < len(AA_new):
    s = str(AA_new[i])
    print(s)
    cmd = 'datalad get -n ' + s
    #subprocess.run(cmd, shell=True)
    cmd = 'datalad get -n ' + s + '/MNINonLinear'
    curr_FD = []
    #subprocess.run(cmd, shell=True)
    for r in ['rfMRI_REST1_AP', 'rfMRI_REST1_PA', 'rfMRI_REST2_AP', 'rfMRI_REST2_PA']:
        if os.path.exists(s + '/MNINonLinear/Results/' + r ):
            mt_file = s + '/MNINonLinear/Results/' + r + '/Movement_RelativeRMS_mean.txt'
            cmd = 'datalad get -s inm7-storage ' + mt_file
            #subprocess.run(cmd, shell=True)
            with open(mt_file) as file:
                curr_FD.append(float(file.readlines()[0].rstrip()))
            FD_AA[i] = np.mean(np.asarray(curr_FD))
    i += 1

FD_WA = np.empty(len(WA_new))
FD_WA[:] = np.nan
print('Collecting FD from WA')
i = 0
while i < len(WA_new):
    s = str(WA_new[i])
    print(s)
    cmd = 'datalad get -n ' + s
    #subprocess.run(cmd, shell=True)
    cmd = 'datalad get -n ' + s + '/MNINonLinear'
    #subprocess.run(cmd, shell=True)
    curr_FD = []
    for r in ['rfMRI_REST1_AP', 'rfMRI_REST1_PA', 'rfMRI_REST2_AP', 'rfMRI_REST2_PA']:
        if os.path.exists(s + '/MNINonLinear/Results/' + r ):
            mt_file = s + '/MNINonLinear/Results/' + r + '/Movement_RelativeRMS_mean.txt'
            cmd = 'datalad get -s inm7-storage ' + mt_file
            #subprocess.run(cmd, shell=True)
            with open(mt_file) as file:
                curr_FD.append(float(file.readlines()[0].rstrip()))
            FD_WA[i] = np.mean(np.asarray(curr_FD))
    i += 1

# normalize traits
FD_AA, FD_WA = norm_trait(FD_AA, FD_WA)
age_AA, age_WA = norm_trait(age_AA, age_WA)
hand_AA, hand_WA = norm_trait(hand_AA, hand_WA)
sex_AA, sex_WA = norm_trait(sex_AA, sex_WA)

# Hungarian match
FD_diff = (np.array([FD_WA]) - np.array([FD_AA]).T) ** 2
age_diff = (np.array([age_WA]) - np.array([age_AA]).T) ** 2
hand_diff = (np.array([hand_WA]) - np.array([hand_AA]).T) ** 2
sex_diff = (np.array([sex_WA]) - np.array([sex_AA]).T) **2
print(FD_diff)

cost = np.sqrt(FD_diff + age_diff + hand_diff + sex_diff)
curr_avg_cost = 10 ** 5
i = 0
while curr_avg_cost > args.cost_ub and len(AA_new) > 0:
    if i > 0:
        cost = np.delete(cost, outlier, axis=0)
        AA_new.pop(outlier)
    row_ind, col_ind = linear_sum_assignment(cost)
    curr_avg_cost = cost[row_ind, col_ind].sum() / len(row_ind)
    print('curr_avg_cost = ' + "%.4f" % curr_avg_cost)
    cost_eachAA = cost[row_ind, col_ind]
    print('cost_eachAA:')
    print(cost_eachAA)
    outlier = np.argmax(cost_eachAA)
    i += 1

print(type(col_ind))
WA_new = np.array(WA_new)[col_ind].tolist()

# save output
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)
basename = os.path.basename(os.path.splitext(args.subj_ls)[0])
WA_ls = os.path.join(args.outdir, basename + '_matchedWA_ub' + str(args.cost_ub) + '.txt')
AA_ls = os.path.join(args.outdir, basename + '_matchedAA_ub' + str(args.cost_ub) + '.txt')
full_ls = os.path.join(args.outdir, basename + '_matchedWAAA_ub' + str(args.cost_ub) + '.txt')
with open(WA_ls, 'w') as f:
    for item in WA_new:
        f.write("%s\n" % item)
with open(AA_ls, 'w') as f:
    for item in AA_new:
        f.write("%s\n" % item)
with open(full_ls, 'w') as f:
    for item in WA_new+AA_new:
        f.write("%s\n" % item)

