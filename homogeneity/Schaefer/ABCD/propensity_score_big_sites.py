import os, argparse, random, subprocess
import pandas as pd
import numpy as np
import scipy.io
from math import pi
from softmaxRegress import *

'''
Example
subj_ls=/data/project/parcellate_ABCD_preprocessed/scripts/lists/subjects_rs_censor.txt
censor_mat=/data/project/parcellate_ABCD_preprocessed/scripts/lists/subjects_rs_censor.mat
outmat=/data/project/AfrAm_FuncParc/data/homogeneity/Schaefer/ABCD/site_effects/propensity_6bigsites_White.mat
site_ls=/data/project/AfrAm_FuncParc/code/AfrAm_FuncParc/homogeneity/Schaefer/ABCD/lists/big_sites.txt
python3 propensity_score_big_sites.py --subj_ls $subj_ls --censor_mat $censor_mat --site_ls $site_ls --outmat $outmat --race "1"
'''

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
parser.add_argument('--race', help='Race group under investigation.')
parser.add_argument('--site_ls', help='List of selected big sites.')
parser.add_argument('--outmat', help='Output .mat file containing the calcuated propensity scores.')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]

subjects_csv = ['NDAR_' + line[8:] for line in subjects ]

# read site list
with open(args.site_ls) as file:
    sites = file.readlines()
    sites = [line.rstrip() for line in sites]
sites_dict = dict(zip(sites, range(len(sites))))

# read csv files, grab subset of the dataframe that is necessary
df_demo = pd.read_csv(args.demo_csv, delimiter='\t', low_memory=False)
df_demo = df_demo[df_demo.subjectkey.isin(subjects_csv) & df_demo.eventname.isin(['baseline_year_1_arm_1']) & df_demo.race_ethnicity.isin([args.race])]
df_demo = df_demo[df_demo.subjectkey.isin(subjects_csv)  ]
df_demo = df_demo[['subjectkey', 'race_ethnicity', 'interview_age', 'sex']]

df_hand = pd.read_csv(args.hand_csv, delimiter='\t')
df_hand = df_hand[df_hand.subjectkey.isin(subjects_csv) & df_hand.eventname.isin(['baseline_year_1_arm_1'])]
# 1=right handed; 2=left handed; 3=mixed handed
df_hand = df_hand[['subjectkey', 'ehi_y_ss_scoreb']]

df_site = pd.read_csv(args.site_csv, delimiter='\t', low_memory=False)
df_site = df_site[df_site.subjectkey.isin(subjects_csv) & df_site.eventname.isin(['baseline_year_1_arm_1']) & df_site.site_id_l.isin(sites)]
df_site = df_site[['subjectkey', 'site_id_l']]

subj_race = df_demo[df_demo.race_ethnicity == args.race].subjectkey.tolist()
subj_site = df_site.subjectkey.tolist()
subj_interest = [s for s in subj_race if s in subj_site]

age = []
sex = []
hand = []
site = []
for s in subj_interest:
    age += df_demo[df_demo.subjectkey == s].interview_age.tolist()
    sex += df_demo[df_demo.subjectkey == s].sex.tolist()
    hand += df_hand[df_hand.subjectkey == s].ehi_y_ss_scoreb.tolist()
    curr_site = df_site[df_site.subjectkey == s].site_id_l.tolist()
    site.append(sites_dict[curr_site[0]])
age = np.asarray(age).astype(float)
sex = np.asarray([0 if i == 'F' else 1 for i in sex]).astype(float)
hand = np.asarray(hand).astype(float)
site = np.asarray(site)
print(site)

soi_new = ['sub-' + s[:4] + s[5:] for s in subj_interest]  # subject IDs (of interest) in BIDS format
ses = 'ses-baselineYear1Arm1'
censor = scipy.io.loadmat(args.censor_mat)


FD = np.empty(len(soi_new))
FD[:] = np.nan
print('Collecting FD for subjects of interest')
i = 0
while i < len(soi_new):
    s = str(soi_new[i])
    #print(s)
    os.chdir(args.data_dir)
    cmd = 'datalad get -n ' + s
    #subprocess.run(cmd, shell=True)
    os.chdir(os.path.join(args.data_dir, s, ses, 'func'))

    idx_bool = [s in censor['subjects'][0][j] for j in range(len(censor['subjects'][0]))]
    runs = censor['pass_runs'][0][idx_bool][0][0]

    curr_FD = np.empty(len(runs))
    curr_FD[:] = np.nan
    k=0
    while k < len(runs):
        run = runs[k][0]
        mt_tsv = s + '_' + ses + '_task-rest_' + run + '_desc-includingFD_motion.tsv'
        cmd = 'datalad get -s inm7-storage ' + mt_tsv
        #subprocess.run(cmd, shell=True)
        # for some run, the "desc-includingFD_motion.tsv" file doesn't exist
        # calculate FD from 6 motion parameters
        if not os.path.exists(mt_tsv):
            print('Warning: ' + mt_tsv + ' file doesn\'t exist.')
            mt_tsv = s + '_' + ses + '_task-rest_' + run + '_motion.tsv'
            cmd = 'cat ' + mt_tsv + ' | tr -s \'([\t]+)\' \',\' > tmp.tsv' # replace multiple \t to a single comma
            #subprocess.run(cmd, shell=True)
            # add comma to the beginning of the first line (because there are extra tabs from line 2 in the original file); 
            # remove the first comma of each line (remove the extra tab); 
            # remove the last comma of each line (because there are extra tabs at the end of each line in the original file)
            cmd = 'echo ",$(cat tmp.tsv)" > tmp2.tsv; cut -c 2- < tmp2.tsv > tmp3.tsv; sed -i \'s/.$//\' tmp3.tsv'
            #subprocess.run(cmd, shell=True)
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
    FD[i] = np.mean(curr_FD)
    i += 1
os.chdir(args.data_dir)
FD = np.asarray(FD).astype(float)


# construct feature matrix
X = np.array([[age[i], sex[i], hand[i], FD[i]] for i in range(len(subj_interest))])
#X = np.array([[age[i], sex[i], hand[i]] for i in range(len(subj_interest))])
print(X)
# softmax regression training
lr = 0.0001 # learning rate
epochs = 2000
w, b, losses = fit(X, site, lr, len(sites), epochs)
site_pred, propensity = predict(X, w, b)
print(accuracy(site, site_pred))
scipy.io.savemat(args.outmat, {'propensity': propensity, 'site_encode':site, 'sites': sites, 'subj_interest': subj_interest, 'age': age, 'sex': sex, 'hand': hand, 'FD': FD})