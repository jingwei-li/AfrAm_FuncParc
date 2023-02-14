import os, argparse, random, subprocess
import pandas as pd
import numpy as np
from scipy.optimize import linear_sum_assignment
import scipy.io
from math import pi

def norm_trait(trait_AA_in, trait_WA_in):
    trait_mean = np.mean(np.concatenate((trait_AA_in, trait_WA_in), axis=None))
    trait_std = np.std(np.concatenate((trait_AA_in, trait_WA_in), axis=None))
    trait_AA_out = (trait_AA_in - trait_mean) / trait_std
    trait_WA_out = (trait_WA_in - trait_mean) / trait_std
    return trait_AA_out, trait_WA_out

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--demo_csv', help='The CSV file containing demographic (age, sex, race/ethnicity) information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/acspsw03.txt')
parser.add_argument('--hand_csv', help='The CSV file containing handedness information. (absolute path)',
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_ehis01.txt')
parser.add_argument('--site_csv', help='The CSV file containing site information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_lt01.txt')
parser.add_argument('--data_dir', help='The local directory of ABCD datalad repository (DCAN-lab preprocessed data).',
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/derivatives/abcd-hcp-pipeline')
parser.add_argument('--censor_mat', help='A .mat file containing the information of which runs of each subject have passed the \
    censoring criterion. It is the output file of https://github.com/jingwei-li/Parcellate_ABCD_DCANpreproc/blob/main/compute_RSFC_with_censor.m')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('--cost_ub', type=float, help='Upper bound of assignment cost', default=1.)
parser.add_argument('--outdir', help='Output directory')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]

subjects_csv = ['NDAR_' + line[8:] for line in subjects ]

# read csv files, grab subset of the dataframe that is necessary
df_demo = pd.read_csv(args.demo_csv, delimiter='\t', low_memory=False)
df_demo = df_demo[df_demo.subjectkey.isin(subjects_csv) & df_demo.eventname.isin(['baseline_year_1_arm_1'])]
df_demo = df_demo[['subjectkey', 'race_ethnicity', 'interview_age', 'sex']]

df_hand = pd.read_csv(args.hand_csv, delimiter='\t')
df_hand = df_hand[df_hand.subjectkey.isin(subjects_csv) & df_hand.eventname.isin(['baseline_year_1_arm_1'])]
# 1=right handed; 2=left handed; 3=mixed handed
df_hand = df_hand[['subjectkey', 'ehi_y_ss_scoreb']]

df_site = pd.read_csv(args.site_csv, delimiter='\t')
df_site = df_site[df_site.subjectkey.isin(subjects_csv) & df_site.eventname.isin(['baseline_year_1_arm_1'])]
df_site = df_site[['subjectkey', 'site_id_l']]

# race_ethnicity: 1=White, 2=Black, 3=Hispanic, 4=Asian, 5=Other
WA = df_demo[df_demo.race_ethnicity == 1].subjectkey.tolist()
AA = df_demo[df_demo.race_ethnicity == 2].subjectkey.tolist()

# get age, sex, handedness of each subject
age_AA = []
sex_AA = []
hand_AA = []
site_AA = []
for i in AA:
    age_AA += df_demo[df_demo.subjectkey == i].interview_age.tolist()
    sex_AA += df_demo[df_demo.subjectkey == i].sex.tolist()
    hand_AA += df_hand[df_hand.subjectkey == i].ehi_y_ss_scoreb.tolist()
    site_AA += df_site[df_site.subjectkey == i].site_id_l.tolist()
age_AA = np.asarray(age_AA)
sex_AA = [0 if i == 'F' else 1 for i in sex_AA]
hand_AA = np.asarray(hand_AA).astype(float)
site_AA = [int("".join(x.split('site'))) for x in site_AA]

age_WA = []
sex_WA = []
hand_WA = []
site_WA = []
for i in WA:
    age_WA += df_demo[df_demo.subjectkey == i].interview_age.tolist()
    sex_WA += df_demo[df_demo.subjectkey == i].sex.tolist()
    hand_WA += df_hand[df_hand.subjectkey == i].ehi_y_ss_scoreb.tolist()
    site_WA += df_site[df_site.subjectkey == i].site_id_l.tolist()
age_WA = np.asarray(age_WA)
sex_WA = [0 if i == 'F' else 1 for i in sex_WA]
hand_WA = np.asarray(hand_WA).astype(float)
site_WA = [int("".join(x.split('site'))) for x in site_WA]


# get FD for each subject
WA_new = ['sub-' + s[:4] + s[5:] for s in WA]
AA_new = ['sub-' + s[:4] + s[5:] for s in AA]

ses = 'ses-baselineYear1Arm1'
censor = scipy.io.loadmat(args.censor_mat)

FD_AA = np.empty(len(AA_new))
FD_AA[:] = np.nan
print('Collecting FD from AA')
i = 0
while i < len(AA_new):
    s = str(AA_new[i])
    print(s)
    os.chdir(args.data_dir)
    cmd = 'datalad get -n ' + s
    subprocess.run(cmd, shell=True)
    os.chdir(os.path.join(args.data_dir, s, ses, 'func'))

    idx_bool = [s in censor['subjects'][0][j] for j in range(len(censor['subjects'][0]))]
    runs = censor['pass_runs'][0][idx_bool][0][0]
    #print(runs)
    curr_FD = np.empty(len(runs))
    curr_FD[:] = np.nan
    k=0
    while k < len(runs):
        run = runs[k][0]
        mt_tsv = s + '_' + ses + '_task-rest_' + run + '_desc-includingFD_motion.tsv'
        cmd = 'datalad get -s inm7-storage ' + mt_tsv
        subprocess.run(cmd, shell=True)
        # for some run, the "desc-includingFD_motion.tsv" file doesn't exist
        # calculate FD from 6 motion parameters
        if not os.path.exists(mt_tsv):
            print('Warning: ' + mt_tsv + ' file doesn\'t exist.')
            mt_tsv = s + '_' + ses + '_task-rest_' + run + '_motion.tsv'
            cmd = 'cat ' + mt_tsv + ' | tr -s \'([\t]+)\' \',\' > tmp.tsv' # replace multiple \t to a single comma
            subprocess.run(cmd, shell=True)
            # add comma to the beginning of the first line (because there are extra tabs from line 2 in the original file); 
            # remove the first comma of each line (remove the extra tab); 
            # remove the last comma of each line (because there are extra tabs at the end of each line in the original file)
            cmd = 'echo ",$(cat tmp.tsv)" > tmp2.tsv; cut -c 2- < tmp2.tsv > tmp3.tsv; sed -i \'s/.$//\' tmp3.tsv'
            subprocess.run(cmd, shell=True)
            mt = pd.read_csv('tmp3.tsv', delimiter='\t')
            # for some run, there isn't extra tab at the end of first line. Therefore the previous step would remove the 't'
            if not 'RotZDt' in mt.columns:
                mt = mt.rename(columns={'RotZD': 'RotZDt'})
            # calculate FD!
            FD_ts = np.abs(np.array(mt['XDt'])) + np.abs(np.array(mt['YDt'])) + np.abs(np.array(mt['ZDt'])) + \
                50*pi/360 * (np.abs(np.array(mt['RotXDt'])) + np.abs(np.array(mt['RotYDt'])) + np.abs(np.array(mt['RotZDt'])))
        else:
            mt = pd.read_csv(mt_tsv, delimiter=' ')
            FD_ts = np.array(mt['framewise_displacement'])
        
        curr_FD[k] = np.mean(FD_ts)
        #print(np.count_nonzero(np.greater(FD_ts, 0.3)))
        k += 1
    #print(curr_FD)
    FD_AA[i] = np.mean(curr_FD)
    i += 1
os.chdir(args.data_dir)

FD_WA = np.empty(len(WA_new))
FD_WA[:] = np.nan
print('Collecting FD from WA')
i = 0
while i < len(WA_new):
    s = str(WA_new[i])
    print(s)
    os.chdir(args.data_dir)
    cmd = 'datalad get -n ' + s
    subprocess.run(cmd, shell=True)
    os.chdir(os.path.join(args.data_dir, s, ses, 'func'))

    idx_bool = [s in censor['subjects'][0][j] for j in range(len(censor['subjects'][0]))]
    runs = censor['pass_runs'][0][idx_bool]
    curr_FD = np.empty(len(runs))
    curr_FD[:] = np.nan
    k = 0
    while k < len(runs):
        run = runs[0][0][k][0]
        mt_tsv = s + '_' + ses + '_task-rest_' + run + '_desc-includingFD_motion.tsv'
        cmd = 'datalad get -s inm7-storage ' + mt_tsv
        subprocess.run(cmd, shell=True)
        # for some run, the "desc-includingFD_motion.tsv" file doesn't exist
        # calculate FD from 6 motion parameters
        if not os.path.exists(mt_tsv):
            mt_tsv = s + '_' + ses + '_task-rest_' + run + '_motion.tsv'
            cmd = 'cat ' + mt_tsv + ' | tr -s \'([\t]+)\' \',\' > tmp.tsv' # replace multiple \t to a single comma
            subprocess.run(cmd, shell=True)
            # add comma to the beginning of the first line (because there are extra tabs from line 2 in the original file); 
            # remove the first comma of each line (remove the extra tab); 
            # remove the last comma of each line (because there are extra tabs at the end of each line in the original file)
            cmd = 'echo ",$(cat tmp.tsv)" > tmp2.tsv; cut -c 2- < tmp2.tsv > tmp3.tsv; sed -i \'s/.$//\' tmp3.tsv'
            subprocess.run(cmd, shell=True)
            mt = pd.read_csv('tmp3.tsv', delimiter='\t')
            # for some run, there isn't extra tab at the end of first line. Therefore the previous step would remove the 't'
            if not 'RotZDt' in mt.columns:
                mt = mt.rename(columns={'RotZD': 'RotZDt'})
            # calculate FD!
            FD_ts = np.abs(np.array(mt['XDt'])) + np.abs(np.array(mt['YDt'])) + np.abs(np.array(mt['ZDt'])) + \
                50*pi/360 * (np.abs(np.array(mt['RotXDt'])) + np.abs(np.array(mt['RotYDt'])) + np.abs(np.array(mt['RotZDt'])))
        else:
            mt = pd.read_csv(mt_tsv, delimiter=' ')
            FD_ts = np.array(mt['framewise_displacement'])
        
        curr_FD[k] = np.mean(FD_ts)
        k += 1
    #print(curr_FD)
    FD_WA[i] = np.mean(curr_FD)
    i += 1
os.chdir(args.data_dir)


# normalize traits
FD_AA, FD_WA = norm_trait(FD_AA, FD_WA)
age_AA, age_WA = norm_trait(age_AA, age_WA)
hand_AA, hand_WA = norm_trait(hand_AA, hand_WA)
sex_AA, sex_WA = norm_trait(sex_AA, sex_WA)

# Hungarian match
sel_AA = []
sel_WA = []
# within each site
for st in np.unique(site_AA + site_WA):
    print('site ' + str(st))
    curr_AAidx = [i for i, x in enumerate(site_AA) if x == st]
    curr_WAidx = [i for i, x in enumerate(site_WA) if x == st]
    curr_AA = [AA_new[i] for i in curr_AAidx]
    curr_WA = [WA_new[i] for i in curr_WAidx]
    print('Original len(curr_AA) = ' + str(len(curr_AA)))
    print('         len(curr_WA) = ' + str(len(curr_WA)))
    curr_FD_AA = [FD_AA[i] for i in curr_AAidx]
    curr_FD_WA = [FD_WA[i] for i in curr_WAidx]
    curr_age_AA = [age_AA[i] for i in curr_AAidx]
    curr_age_WA = [age_WA[i] for i in curr_WAidx]
    curr_hand_AA = [hand_AA[i] for i in curr_AAidx]
    curr_hand_WA = [hand_WA[i] for i in curr_WAidx]
    curr_sex_AA = [sex_AA[i] for i in curr_AAidx]
    curr_sex_WA = [sex_WA[i] for i in curr_WAidx]

    if len(curr_AAidx) <= len(curr_WAidx):
        FD_diff = (np.array([curr_FD_WA]) - np.array([curr_FD_AA]).T) ** 2
        age_diff = (np.array([curr_age_WA]) - np.array([curr_age_AA]).T) ** 2
        hand_diff = (np.array([curr_hand_WA]) - np.array([curr_hand_AA]).T) ** 2
        sex_diff = (np.array([curr_sex_WA]) - np.array([curr_sex_AA]).T) **2

        cost = np.sqrt(FD_diff + age_diff + hand_diff + sex_diff)
        print('Shape of cost matrix = ')
        print(cost.shape)
        curr_avg_cost = 10 ** 5
        i = 0
        while curr_avg_cost > args.cost_ub and len(curr_AA) >= 0:
            if i > 0:
                cost = np.delete(cost, outlier, axis=0)
                curr_AA.pop(outlier)
            row_ind, col_ind = linear_sum_assignment(cost)
            curr_avg_cost = cost[row_ind, col_ind].sum() / len(row_ind)
            print('curr_avg_cost = ' + "%.4f" % curr_avg_cost)
            cost_eachAA = cost[row_ind, col_ind]
            print('cost_eachAA:')
            print(cost_eachAA)
            if len(cost_eachAA) > 0:
                outlier = np.argmax(cost_eachAA)
            i += 1
        curr_WA = np.array(curr_WA)[col_ind].tolist()

    else:
        FD_diff = (np.array([curr_FD_AA]) - np.array([curr_FD_WA]).T) ** 2
        age_diff = (np.array([curr_age_AA]) - np.array([curr_age_WA]).T) ** 2
        hand_diff = (np.array([curr_hand_AA]) - np.array([curr_hand_WA]).T) ** 2
        sex_diff = (np.array([curr_sex_AA]) - np.array([curr_sex_WA]).T) **2

        cost = np.sqrt(FD_diff + age_diff + hand_diff + sex_diff)
        print('Shape of cost matrix = ')
        print(cost.shape)
        curr_avg_cost = 10 ** 5
        i = 0
        while curr_avg_cost > args.cost_ub and len(curr_WA) >= 0:
            if i > 0:
                cost = np.delete(cost, outlier, axis=0)
                curr_WA.pop(outlier)
            row_ind, col_ind = linear_sum_assignment(cost)
            curr_avg_cost = cost[row_ind, col_ind].sum() / len(row_ind)
            print('curr_avg_cost = ' + "%.4f" % curr_avg_cost)
            cost_eachWA = cost[row_ind, col_ind]
            print('cost_eachWA:')
            print(cost_eachWA)
            if len(cost_eachWA) > 0:
                outlier = np.argmax(cost_eachWA)
            i += 1
        curr_AA = np.array(curr_AA)[col_ind].tolist()
    
    sel_AA = sel_AA + curr_AA
    sel_WA = sel_WA + curr_WA
    print('Matched len(curr_AA) = ' + str(len(curr_AA)))
    print('        len(curr_WA) = ' + str(len(curr_WA)))
    print(curr_AA)
    print(curr_WA)

# save output
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)
basename = os.path.basename(os.path.splitext(args.subj_ls)[0])
WA_ls = os.path.join(args.outdir, basename + '_matchedWA_ub' + str(args.cost_ub) + '.txt')
AA_ls = os.path.join(args.outdir, basename + '_matchedAA_ub' + str(args.cost_ub) + '.txt')
full_ls = os.path.join(args.outdir, basename + '_matchedWAAA_ub' + str(args.cost_ub) + '.txt')
with open(WA_ls, 'w') as f:
    for item in sel_WA:
        f.write("%s\n" % item)
with open(AA_ls, 'w') as f:
    for item in sel_AA:
        f.write("%s\n" % item)
with open(full_ls, 'w') as f:
    for item in sel_WA+sel_AA:
        f.write("%s\n" % item)
