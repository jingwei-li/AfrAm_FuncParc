import os, argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--demo_csv', help='The CSV file containing demographic (age, sex, race/ethnicity) information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/acspsw03.txt')
parser.add_argument('--site_csv', help='The CSV file containing site information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_lt01.txt')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('--outfig', help='Output figure.')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]

subjects_csv = ['NDAR_' + line[8:] for line in subjects ]

# read csv files, grab subset of the dataframe that is necessary
# race_ethnicity: 1=White, 2=Black, 3=Hispanic, 4=Asian, 5=Other
df_demo = pd.read_csv(args.demo_csv, delimiter='\t', low_memory=False)
df_demo = df_demo[df_demo.subjectkey.isin(subjects_csv) & df_demo.eventname.isin(['baseline_year_1_arm_1'])]
df_demo = df_demo[['subjectkey', 'race_ethnicity', 'sex']]
subjects_demo = df_demo.subjectkey.tolist()
subjects_csv = [s for s in subjects_csv if s in subjects_demo]

df_site = pd.read_csv(args.site_csv, delimiter='\t')
df_site = df_site[df_site.subjectkey.isin(subjects_csv) & df_site.eventname.isin(['baseline_year_1_arm_1'])]
df_site = df_site[['subjectkey', 'site_id_l']]
subjects_site = df_site.subjectkey.tolist()
subjects_csv = [s for s in subjects_csv if s in subjects_site]

sex = []
site = []
race = []
print(len(subjects_csv))
for i in subjects_csv:
    sex += df_demo[df_demo.subjectkey == i].sex.tolist()
    site += df_site[df_site.subjectkey == i].site_id_l.tolist()

    curr_race = df_demo[df_demo.subjectkey == i].race_ethnicity.tolist()
    
    if len(curr_race) == 0 or np.nan in curr_race:
        curr_race = ['Unknown']
    elif curr_race[0] == '1':
        curr_race[0] = 'White'
    elif curr_race[0] == '2':
        curr_race[0] = 'Black'
    elif curr_race[0] == '3':
        curr_race[0] = 'Hispanic'
    elif curr_race[0] == '4':
        curr_race[0] = 'Asian'
    elif curr_race[0] == '5':
        curr_race[0] = 'Other'
        
    race += curr_race
sex_uniq = sorted(list(set(sex)))
site_uniq = sorted(list(set(site)))
race_uniq = list(set(race))

print(sex_uniq)
print(site_uniq)
print(race_uniq)

fig = plt.figure(figsize=(16, 8))
# transparent backgroung
ax = plt.gca()
#ax.patch.set_alpha(0)
# invisible right and upper axes
ax.spines['right'].set_visible(False)
ax.spines['top'].set_visible(False)
ax.yaxis.set_ticks_position('left')
ax.xaxis.set_ticks_position('bottom')

plt.hist(site, len(site_uniq))
plt.savefig(args.outfig, format='png')

print(len(site))
print(len(race))
print(len(sex))
for s in site_uniq:
    indices = [i for i in range(len(site)) if site[i] == s]
    curr_sex = [sex[i] for i in range(len(site)) if site[i] == s]
    nF = curr_sex.count('F')
    nM = curr_sex.count('M')
    curr_race = [race[i] for i in range(len(site)) if site[i] == s]
    nW = curr_race.count('White')
    nB = curr_race.count('Black')
    nH = curr_race.count('Hispanic')
    nA = curr_race.count('Asian')
    nO = curr_race.count('Other')
    nU = curr_race.count('Unknown')

    print(s)
    print('\tTotal size: ' + str(len(indices)))
    print('\tF:M = ' + str(nF) + ':' + str(nM))
    print('\tW:B:H:A:O:U = ' + str(nW) + ':' + str(nB) + ':' + str(nH) + ':' + str(nA) + ':' + str(nO) + ':' + str(nU))
    
