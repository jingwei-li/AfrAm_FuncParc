# Calculate RSFC homogeneity of Schaefer parcellation using the GSP dataset

## Step 1. check which subjects have rs-fMRI

```matlab
subj_with_rfMRI(GSP_dir, out_dir)
```

`GSP_dir`: the local fullpath to the datalad repo of the GSP dataset, e.g. `/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/processed/rs_fix/GSP`.

`out_dir`: full path of output directory, e.g. `/data/project/AfrAm_FuncParc/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists`.

## Step 2. randomly select the same number of white Americans and others

```
python3 rand_subject_equalOtherWA.py --subj_ls $subj_ls --outdir $outdir -N 500
```

`$subj_ls`: output from step 1, e.g. `/data/project/AfrAm_FuncParc/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists/subject_rfMRI.txt`.

`outdir`: output directory, e.g. `/data/project/AfrAm_FuncParc/code/AfrAm_FuncParc/homogeneity/Schaefer/GSP/lists`.

## Step 3. post-processing fMRI data (nuisance regression w/wo projection to fsaverage space)

On a high-performance computer with HTCondor scheduler, use this script to submit jobs:

```
./gen_submit_postproc_fMRI.sh | condor_submit
```

If projecting fMRI data to fsaverage6 space, run

```
gen_submit_proj_MNIpostproc2fsaverage.sh | condor_submit
```

## Step 4. compute RSFC homogeneity for each group

### MNI space

On a high-performance computer with HTCondor, use this script to submit jobs:

```
./gen_submit_rsfc_homo_schaefer.sh | condor_submit
```

### Fsaverage space

```
./gen_submit_rsfc_homo_schaefer_surf.sh | condor_submit
```

## Step 5. plot the homogeneity of white Americans vs. others

```matlab
cd ../HCP
violin_rsfc_homo_schaefer(homo_grp1, homo_grp2, grp1_name, grp2_name, out_png)
```

`homo_grp1`: full path to the homogeneity .mat file of group 1, e.g. `'/data/project/AfrAm_FuncParc/data/homogeneity/Schaefer/GSP/rsfc_homo_400_rand500Other_surf.mat'` for fsaverage space results. 

`homo_grp2`: full path to the homogeneity .mat file of group 2, e.g. `'/data/project/AfrAm_FuncParc/data/homogeneity/Schaefer/GSP/rsfc_homo_400_rand500WA_surf.mat'`.

`grp1_name`: name of the first group for plotting, e.g. `'Other'`.

`grp2_name`: name of the second group for plotting, e.g. `'WA'`.

`out_png`: output figure name, e.g. `'//data/project/AfrAm_FuncParc/data/homogeneity/Schaefer/GSP/rsfc_homo_400_OtherWA_rand500_surf.png'`
