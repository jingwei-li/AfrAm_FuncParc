import os, argparse, random
import pandas as pd

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--csv', help='The CSV file containing race/ethnicity information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/hcp/hcp_aging/phenotype/ndar_subject01.txt')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('-N', type=int, help='Number of subjects to be selected per group.', default=100)
parser.add_argument('--outdir', help='Output directory')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]
    subjects = [line[0:10] for line in subjects]
print(subjects)

# read csv file, grab subset of the dataframe that is necessary
df = pd.read_csv(args.csv, delimiter='\t')
df = df[df.src_subject_id.isin(subjects)]
df = df[['src_subject_id', 'race']]

# race
WA = df[df.race == 'White'].src_subject_id.tolist()
AA = df[df.race == 'Black or African American'].src_subject_id.tolist()
random.seed(10)
WA = random.sample(WA, args.N)
AA = random.sample(AA, args.N)

# write subject IDs into two separate text files
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)
basename = os.path.basename(os.path.splitext(args.subj_ls)[0])
WA_ls = os.path.join(args.outdir, basename + '_rand' + str(args.N) + 'WA.txt')
AA_ls = os.path.join(args.outdir, basename + '_rand' + str(args.N) + 'AA.txt')
full_ls = os.path.join(args.outdir, basename + '_rand' + str(args.N) + 'WA' + str(args.N) + 'AA.txt')

with open(WA_ls, 'w') as f:
    for item in WA:
        item = item + '_V1_MR'
        f.write("%s\n" % item)
with open(AA_ls, 'w') as f:
    for item in AA:
        item = item + '_V1_MR'
        f.write("%s\n" % item)
with open(full_ls, 'w') as f:
    for item in WA+AA:
        item = item + '_V1_MR'
        f.write("%s\n" % item)