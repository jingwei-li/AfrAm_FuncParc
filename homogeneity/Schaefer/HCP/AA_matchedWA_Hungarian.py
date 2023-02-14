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
parser.add_argument('--restrict_csv', help='The CSV file containing race/ethnicity information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/HCP-openaccess-csv/RESTRICTED_jingweili_3_11_2022_1200subjects.csv')
parser.add_argument('--unrestricted_csv', help='The unrestricted CSV file of the HCP-YA dataset. (absolute path)',
    default='/data/project/AfrAm_FuncParc/data/datasets/HCP-openaccess-csv/Behavioral_jingweili_3_11_2022_1200subjects.csv')
parser.add_argument('--data_dir', help='The local directory of HCP-YA datalad repository.',
    default='/data/project/AfrAm_FuncParc/data/datasets/human-connectome-project-openaccess')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('--cost_ub', type=float, help='Upper bound of assignment cost', default=1.)
parser.add_argument('--outdir', help='Output directory')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]

# read csv file, grab subset of the dataframe that is necessary
df_restrict = pd.read_csv(args.restrict_csv, delimiter=',')
df_restrict = df_restrict[df_restrict.Subject.isin(subjects)]
df_restrict = df_restrict[['Subject', 'Race', 'Age_in_Yrs', 'Handedness']]

# race
WA = df_restrict[df_restrict.Race == 'White'].Subject.tolist()
AA = df_restrict[df_restrict.Race == 'Black or African Am.'].Subject.tolist()

# get age, sex, handedness of each subject
df_unrestrict = pd.read_csv(args.unrestricted_csv, delimiter=',')
df_unrestrict = df_unrestrict[df_unrestrict.Subject.isin(subjects)]
df_unrestrict = df_unrestrict[['Subject', 'Gender']]

age_AA = []
hand_AA = []
gender_AA = []
for i in AA:
    age_AA += df_restrict[df_restrict.Subject == i].Age_in_Yrs.tolist()
    hand_AA += df_restrict[df_restrict.Subject == i].Handedness.tolist()
    gender_AA += df_unrestrict[df_unrestrict.Subject == i].Gender.tolist()
age_AA = np.asarray(age_AA)
hand_AA = np.asarray(hand_AA)
gender_AA = [0 if i == 'F' else 1 for i in gender_AA]

age_WA = []
hand_WA = []
gender_WA = []
for i in WA:
    age_WA += df_restrict[df_restrict.Subject == i].Age_in_Yrs.tolist()
    hand_WA += df_restrict[df_restrict.Subject == i].Handedness.tolist()
    gender_WA += df_unrestrict[df_unrestrict.Subject == i].Gender.tolist()
age_WA = np.asarray(age_WA)
hand_WA = np.asarray(hand_WA)
gender_WA = [0 if i == 'F' else 1 for i in gender_WA]


# get FD for each subject
os.chdir(os.path.join(args.data_dir, 'HCP1200'))
FD_AA = np.empty(len(AA))
FD_AA[:] = np.nan
print('Collecting FD from AA')
i = 0
while i < len(AA):
    s = str(AA[i])
    #print(s)
    cmd = 'datalad get -n ' + s
    #subprocess.run(cmd, shell=True)
    cmd = 'datalad get -n ' + s + '/MNINonLinear'
    curr_FD = []
    #subprocess.run(cmd, shell=True)
    for r in ['rfMRI_REST1_LR', 'rfMRI_REST1_RL', 'rfMRI_REST2_LR', 'rfMRI_REST2_RL']:
        if os.path.exists(s + '/MNINonLinear/Results/' + r ):
            mt_file = s + '/MNINonLinear/Results/' + r + '/Movement_RelativeRMS_mean.txt'
            cmd = 'datalad get ' + mt_file
            #subprocess.run(cmd, shell=True)
            with open(mt_file) as file:
                curr_FD.append(float(file.readlines()[0].rstrip()))
            FD_AA[i] = np.mean(np.asarray(curr_FD))
    i += 1

FD_WA = np.empty(len(WA))
FD_WA[:] = np.nan
print('Collecting FD from WA')
i = 0
while i < len(WA):
    s = str(WA[i])
    #print(s)
    cmd = 'datalad get -n ' + s
    #subprocess.run(cmd, shell=True)
    cmd = 'datalad get -n ' + s + '/MNINonLinear'
    curr_FD = []
    #subprocess.run(cmd, shell=True)
    for r in ['rfMRI_REST1_LR', 'rfMRI_REST1_RL', 'rfMRI_REST2_LR', 'rfMRI_REST2_RL']:
        if os.path.exists(s + '/MNINonLinear/Results/' + r ):
            mt_file = s + '/MNINonLinear/Results/' + r + '/Movement_RelativeRMS_mean.txt'
            cmd = 'datalad get ' + mt_file
            #subprocess.run(cmd, shell=True)
            with open(mt_file) as file:
                curr_FD.append(float(file.readlines()[0].rstrip()))
            FD_WA[i] = np.mean(np.asarray(curr_FD))
    i += 1
        
# normalize traits
FD_AA, FD_WA = norm_trait(FD_AA, FD_WA)
age_AA, age_WA = norm_trait(age_AA, age_WA)
hand_AA, hand_WA = norm_trait(hand_AA, hand_WA)
gender_AA, gender_WA = norm_trait(gender_AA, gender_WA)

# Hungarian match
FD_diff = (np.array([FD_WA]) - np.array([FD_AA]).T) ** 2
age_diff = (np.array([age_WA]) - np.array([age_AA]).T) ** 2
hand_diff = (np.array([hand_WA]) - np.array([hand_AA]).T) ** 2
gender_diff = (np.array([gender_WA]) - np.array([gender_AA]).T) **2

cost = np.sqrt(FD_diff + age_diff + hand_diff + gender_diff)
curr_avg_cost = 10 ** 5
i = 0
while curr_avg_cost > args.cost_ub and len(AA) > 0:
    if i > 0:
        cost = np.delete(cost, outlier, axis=0)
        AA.pop(outlier)
    row_ind, col_ind = linear_sum_assignment(cost)
    curr_avg_cost = cost[row_ind, col_ind].sum() / len(row_ind)
    print('curr_avg_cost = ' + "%.4f" % curr_avg_cost)
    cost_eachAA = cost[row_ind, col_ind]
    print('cost_eachAA:')
    print(cost_eachAA)
    outlier = np.argmax(cost_eachAA)
    i += 1

print(type(col_ind))
WA = np.array(WA)[col_ind].tolist()

# save output
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)
basename = os.path.basename(os.path.splitext(args.subj_ls)[0])
WA_ls = os.path.join(args.outdir, basename + '_matchedWA_ub' + str(args.cost_ub) + '.txt')
AA_ls = os.path.join(args.outdir, basename + '_matchedAA_ub' + str(args.cost_ub) + '.txt')
full_ls = os.path.join(args.outdir, basename + '_matchedWAAA_ub' + str(args.cost_ub) + '.txt')
with open(WA_ls, 'w') as f:
    for item in WA:
        f.write("%s\n" % item)
with open(AA_ls, 'w') as f:
    for item in AA:
        f.write("%s\n" % item)
with open(full_ls, 'w') as f:
    for item in WA+AA:
        f.write("%s\n" % item)