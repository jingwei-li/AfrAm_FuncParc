import os, argparse, random
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
propensity = input['propensity']
site = input['site_encode'][0]   # num_subjects x 1 encoded vector (0-len(sites))
sites = input['sites']  # original site names involeved
sites_dict = dict(zip(sites, range(len(sites))))
for si in sites:
    indices = [i for i, e in enumerate(site) if sites_dict[si] == e]
    curr_subj = [input['subj_interest'][i] for i in indices]
    curr_prop = np.asarray([propensity[i] for i in indices])
    # for each subject, calculate the difference between its propensity scores to the center
    # of propensity scores of every other site, then take the mean across sites
    other_sites = list(set(sites) - set([si]))
    prop_dist = np.zeros((curr_prop.shape[0],))
    for sj in other_sites:
        other_indices = [i for i, e in enumerate(site) if sites_dict[sj] == e]
        curr_other_prop = np.asarray([propensity[i] for i in other_indices])
        prop_center = np.mean(curr_other_prop, axis = 0)
        curr_prop_dist = np.sqrt(np.sum(np.square(np.subtract(curr_prop, prop_center)), axis=1))
        prop_dist += curr_prop_dist
    prop_dist = np.divide(prop_dist, len(other_sites))

    sort_ind = np.argsort(prop_dist)
    sel_subj = [curr_subj[i] for i in sort_ind[0:int(args.N)]]
    sel_subj = ['sub-' + s[:4] + s[5:] for s in sel_subj]
    outname = os.path.join(args.outdir, 'matched_subj_' + str(args.N) + '_' + si + args.suffix)
    with open(outname,'w') as tfile:
	    tfile.write('\n'.join(sel_subj))

for si in sites:
    indices = random.sample([i for i, e in enumerate(site) if sites_dict[si] == e], k=int(args.N))
    rand_subj = [input['subj_interest'][i] for i in indices]
    rand_subj = ['sub-' + s[:4] + s[5:] for s in rand_subj]
    outname = os.path.join(args.outdir, 'rand_subj_' + str(args.N) + '_' + si + args.suffix)
    with open(outname,'w') as tfile:
	    tfile.write('\n'.join(rand_subj))