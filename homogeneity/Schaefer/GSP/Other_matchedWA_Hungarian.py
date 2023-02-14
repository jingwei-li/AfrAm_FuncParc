import os, argparse, random, subprocess
import pandas as pd
import numpy as np
from scipy.optimize import linear_sum_assignment
import scipy.io, mat73

def norm_trait(trait_other_in, trait_WA_in):
    trait_mean = np.mean(np.concatenate((trait_other_in, trait_WA_in), axis=None))
    trait_std = np.std(np.concatenate((trait_other_in, trait_WA_in), axis=None))
    trait_other_out = (trait_other_in - trait_mean) / trait_std
    trait_WA_out = (trait_WA_in - trait_mean) / trait_std
    return trait_other_out, trait_WA_out

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--csv', help='The CSV file containing race/ethnicity information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/GSP_extended_140630.csv')
parser.add_argument('--data_dir', help='The local directory of GSP datalad repository.', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/processed/rs_fix/GSP')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('--cost_ub', type=float, help='Upper bound of assignment cost', default=1.)
parser.add_argument('--outdir', help='Output directory')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]
subjects_csv = ['S' + line[1:3] + line[4:] + '_S1' for line in subjects ]

# read csv file, grab subset of the dataframe that is necessary
df = pd.read_csv(args.csv, delimiter=',')
df = df[df.Subject_ID.isin(subjects_csv)]
df = df[['Subject_ID', 'Race_Ethn', 'Sex', 'Hand', 'Age_Bin']]

# race
WA = df[df.Race_Ethn == 'W_NOT_HL'].Subject_ID.tolist()
other = df[df.Race_Ethn == 'Other'].Subject_ID.tolist()

# get age, sex, handedness of each subject
age_WA = []
hand_WA = []
sex_WA = []
for i in WA:
    age_WA += df[df.Subject_ID == i].Age_Bin.tolist()
    hand_WA += df[df.Subject_ID == i].Hand.tolist()
    sex_WA += df[df.Subject_ID == i].Sex.tolist()
age_WA = np.asarray(age_WA)
hand_WA = [0 if i == 'RHT' else 1 for i in hand_WA]
sex_WA = [0 if i == 'F' else 1 for i in sex_WA]

age_Other = []
hand_Other = []
sex_Other = []
for i in other:
    age_Other += df[df.Subject_ID == i].Age_Bin.tolist()
    hand_Other += df[df.Subject_ID == i].Hand.tolist()
    sex_Other += df[df.Subject_ID == i].Sex.tolist()
age_Other = np.asarray(age_Other)
hand_Other = [0 if i == 'RHT' else 1 for i in hand_Other]
sex_Other = [0 if i == 'F' else 1 for i in sex_Other]

# get FD for each subject
os.chdir(args.data_dir)
WA_new = ['s' + s[1:3] + '-' + s[3:7] for s in WA]
other_new = ['s' + s[1:3] + '-' + s[3:7] for s in other]

FD_WA = np.empty(len(WA_new))
FD_WA[:] = np.nan
print('Collecting FD from WA')
i = 0
while i < len(WA_new):
    s = str(WA_new[i])
    print(s)
    mt_file = os.path.join(s, 'ses-01', 'Confounds_' + s + '_ses-01.mat')
    cmd = 'datalad get -s inm7-storage ' + mt_file
    #subprocess.run(cmd, shell=True)
    try:
        mt = scipy.io.loadmat(mt_file)
    except:
        mt = mat73.loadmat(mt_file)
    FD_WA[i] = mt['FD']
    i += 1

FD_Other = np.empty(len(other_new))
FD_Other[:] = np.nan
print('Collecting FD from others')
i = 0
while i < len(other_new):
    s = str(other_new[i])
    print(s)
    mt_file = os.path.join(s, 'ses-01', 'Confounds_' + s + '_ses-01.mat')
    cmd = 'datalad get -s inm7-storage ' + mt_file
    #subprocess.run(cmd, shell=True)
    try:
        mt = scipy.io.loadmat(mt_file)
    except:
        mt = mat73.loadmat(mt_file)
    FD_Other[i] = mt['FD']
    i += 1


# normalize traits
FD_Other, FD_WA = norm_trait(FD_Other, FD_WA)
age_Other, age_WA = norm_trait(age_Other, age_WA)
hand_Other, hand_WA = norm_trait(hand_Other, hand_WA)
sex_Other, sex_WA = norm_trait(sex_Other, sex_WA)

# Hungarian match
FD_diff = (np.array([FD_WA]) - np.array([FD_Other]).T) ** 2
age_diff = (np.array([age_WA]) - np.array([age_Other]).T) ** 2
hand_diff = (np.array([hand_WA]) - np.array([hand_Other]).T) ** 2
sex_diff = (np.array([sex_WA]) - np.array([sex_Other]).T) ** 2

cost = np.sqrt(FD_diff + age_diff + hand_diff + sex_diff)
curr_avg_cost = 10 ** 5
i = 0
while curr_avg_cost > args.cost_ub and len(other_new) > 0:
    if i > 0:
        cost = np.delete(cost, outlier, axis=0)
        other_new.pop(outlier)
    row_ind, col_ind = linear_sum_assignment(cost)
    curr_avg_cost = cost[row_ind, col_ind].sum() / len(row_ind)
    print('curr_avg_cost = ' + "%.4f" % curr_avg_cost)
    cost_eachOther = cost[row_ind, col_ind]
    print('cost_eachOther:')
    print(cost_eachOther)
    outlier = np.argmax(cost_eachOther)
    i += 1

print(type(col_ind))
WA_new = np.array(WA_new)[col_ind].tolist()

# save output
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)
basename = os.path.basename(os.path.splitext(args.subj_ls)[0])
WA_ls = os.path.join(args.outdir, basename + '_matchedWA_ub' + str(args.cost_ub) + '.txt')
other_ls = os.path.join(args.outdir, basename + '_matchedOther_ub' + str(args.cost_ub) + '.txt')
full_ls = os.path.join(args.outdir, basename + '_matchedWAOther_ub' + str(args.cost_ub) + '.txt')
with open(WA_ls, 'w') as f:
    for item in WA_new:
        f.write("%s\n" % item)
with open(other_ls, 'w') as f:
    for item in other_new:
        f.write("%s\n" % item)
with open(full_ls, 'w') as f:
    for item in WA_new + other_new:
        f.write("%s\n" % item)