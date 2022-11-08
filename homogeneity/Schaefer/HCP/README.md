# Calculate RSFC homogeneity of Schaefer parcellation using the HCP-YA dataset

## Step 1. check which subjects have rs-fMRI

```matlab
subj_with_rfMRI(HCP_dir, out_dir)
```

`HCP_dir`: the local fullpath to the datalad repo of the HCP open-access dataset, e.g. `/data/project/AfrAm_FuncParc/data/datasets/human-connectome-project-openaccess`.

`out_dir`: full path of output directory, e.g. `/data/project/AfrAm_FuncParc/code/AfrAm_FuncParc/homogeneity/Schaefer/HCP/lists`.

## Step 2. randomly select the same number of African Americans and white Americans

```
python3 rand_subject_equalAAWA.py --subj_ls $subj_ls --outdir $outdir -N 160
```

`$subj_ls`: output from step 2, e.g. `/data/project/template_t1/data/ABCD_datalad/code/homogeneity/Schaefer/HCP/lists/subject_rfMRI.txt`.

`outdir`: output directory, e.g. `/data/project/template_t1/data/ABCD_datalad/code/homogeneity/Schaefer/HCP/lists`.

## Step 3. compute RSFC homogeneity for each group

On a high-performance computer with HTCondor, use this script to submit jobs:

```
./gen_submit_rsfc_homo_schaefer.sh | condor_submit
```

## Step 4. plot the homogeneity of African/white Americans
