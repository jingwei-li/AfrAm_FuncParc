# Calculate RSFC homogeneity of Schaefer parcellation using the ABCD dataset

## Step 1: generate file lists

```matlab
gen_DCANprep_rsfMRI_fsLR32k_filelist(data_dir, subj_ls, censor_mat, fsLR_file_ls)
```

`data_dir`: the local fullpath to a subfolder in the cloned INM-7 superdataset. It is the directory containing the ABCD data preprocessed by the DCAN lab.

`subj_ls`: the fullpath to a subject list. It should contain the same number of African Americans and white Americans. Generating this subject list borrows a Python script from another GitHub repository (see `README.md` in the `lists` folder).

`censor_mat`: a .mat file containing the information of which runs of each subject have passed the censoring criterion. It is the output file of https://github.com/jingwei-li/Parcellate_ABCD_DCANpreproc/blob/main/compute_RSFC_with_censor.m

`fsLR_file_ls`: fullpath to the output file list.

## Step 2. compute RSFC homogeneity

On a high-performance computer with HTCondor, submit the following job:

```
condor_submit rsfc_homo_schaefer.submit
```

## Step 3. plot the homogeneity of African/white Americans

```matlab
violin_rsfc_homo_schaefer(homo_mat, grp1_name, grp2_name, out_png)
```

`homo_mat`: the output of step 2. E.g. `/data/project/AfrAm_FuncParc/data/homogeneity/Schaefer/ABCD/rsfc_homo_400_AAWA_rand300.mat`.

`grp1_name`: name of the first group for plotting. It should be consistent with the ordering in `homo_mat`.

`grp2_name`: name of the second group for plotting. It should be consistent with the ordering in `homo_mat`.

`out_png`: output figure name, e.g. `/data/project/AfrAm_FuncParc/data/homogeneity/Schaefer/ABCD/rsfc_homo_400_AAWA_rand300.png`.
