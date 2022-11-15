import os, argparse, random
import pandas as pd

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--csv', help='The CSV file containing race/ethnicity information. (absolute path)', 
    default='/data/project/AfrAm_FuncParc/data/datasets/GSP_extended_140630.csv')
parser.add_argument('--subj_ls', help='Full subject list (absolute path).')
parser.add_argument('-N', type=int, help='Number of subjects to be selected per group.', default=100)
parser.add_argument('--outdir', help='Output directory')
args = parser.parse_args()

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]
    subjects = ['S' + line[1:3] + line[4:] + '_S1' for line in subjects ]

# read csv file, grab subset of the dataframe that is necessary
df = pd.read_csv(args.csv, delimiter=',')
df = df[df.Subject_ID.isin(subjects)]
df = df[['Subject_ID', 'Race_Ethn']]

# race
WA = df[df.Race_Ethn == 'W_NOT_HL'].Subject_ID.tolist()
other = df[df.Race_Ethn == 'Other'].Subject_ID.tolist()
random.seed(10)
WA = random.sample(WA, args.N)
other = random.sample(other, args.N)

# write subject IDs into two separate text files
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)
basename = os.path.basename(os.path.splitext(args.subj_ls)[0])
WA_ls = os.path.join(args.outdir, basename + '_rand' + str(args.N) + 'WA.txt')
other_ls = os.path.join(args.outdir, basename + '_rand' + str(args.N) + 'Other.txt')
full_ls = os.path.join(args.outdir, basename + '_rand' + str(args.N) + 'WA' + str(args.N) + 'Other.txt')

with open(WA_ls, 'w') as f:
    for item in WA:
        item = 's' + item[1:3] + '-' + item[3:7]
        f.write("%s\n" % item)
with open(other_ls, 'w') as f:
    for item in other:
        item = 's' + item[1:3] + '-' + item[3:7]
        f.write("%s\n" % item)
with open(full_ls, 'w') as f:
    for item in WA+other:
        item = 's' + item[1:3] + '-' + item[3:7]
        f.write("%s\n" % item)