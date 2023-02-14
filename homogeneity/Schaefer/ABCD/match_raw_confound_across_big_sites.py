import os, argparse
import pandas as pd
import numpy as np
import scipy.io

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--inmat', help='Input .mat file containing the calcuated propensity scores, sites, subject IDs.')
parser.add_argument('--outdir', help='Output directory.')
parser.add_argument('--suffix', help='Suffix of output list names.')
parser.add_argument('-N', help='Number of subjects to keep per site.')
args = parser.parse_args()

if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)

input = scipy.io.loadmat(args.inmat)
site = input['site_encode'][0]   # num_subjects x 1 encoded vector (0-len(sites))
sites = input['sites']  # original site names involeved
sites_dict = dict(zip(sites, range(len(sites))))
age = input['age'][0]
sex = input['sex'][0]
hand = input['hand'][0]
FD = input['FD'][0]

# normalize confound variables
age = age - np.mean(age)
age = np.divide(age, np.std(age))
age = age
sex = sex - np.mean(sex)
sex = np.divide(sex, np.std(sex))
sex = sex
hand = hand - np.mean(hand)
hand = np.divide(hand, np.std(hand))
FD = FD - np.mean(FD)
FD = np.divide(FD, np.std(FD))

for si in sites:
    indices = [i for i, e in enumerate(site) if sites_dict[si] == e]
    curr_subj = [input['subj_interest'][i] for i in indices]
    curr_conf = np.asarray([[age[i], sex[i], hand[i], FD[i]] for i in indices])
    # for each subject, calculate the distance between its confound variables to the center
    # of confound variables of every other site, then take the mean across sites
    other_sites = list(set(sites) - set([si]))
    print(curr_conf.shape)
    conf_dist = np.zeros((curr_conf.shape[0],))

    for sj in other_sites:
        other_indices = [i for i, e in enumerate(site) if sites_dict[sj] == e]
        curr_other_conf = np.asarray([[age[i], sex[i], hand[i], FD[i]] for i in other_indices])
        conf_center = np.mean(curr_other_conf, axis = 0)
        curr_conf_dist = np.sqrt(np.sum(np.square(np.subtract(curr_conf, conf_center)), axis=1))
        conf_dist += curr_conf_dist
    conf_dist = np.divide(conf_dist, len(other_sites))

    sort_ind = np.argsort(conf_dist)
    sel_subj = [curr_subj[i] for i in sort_ind[0:int(args.N)]]
    sel_subj = ['sub-' + s[:4] + s[5:] for s in sel_subj]
    outname = os.path.join(args.outdir, 'raw_conf_matched_subj_' + str(args.N) + '_' + si + args.suffix)
    with open(outname,'w') as tfile:
	    tfile.write('\n'.join(sel_subj))
