# Calculate RSFC homogeneity of Schaefer parcellation using the ABCD dataset

## Step 1: generate file lists

```matlab
gen_DCANprep_rsfMRI_fsLR32k_filelist(data_dir, subj_ls, censor_mat, fsLR_file_ls)
```

`data_dir`: the local fullpath to a subfolder in the cloned INM-7 superdataset. It is the directory containing the ABCD data preprocessed by the DCAN lab.

`subj_ls`: the fullpath to a subject list. It should contain the same number of African Americans and white Americans. Generating this subject list borrows a Python script from another GitHub repository (see `README.md` in the `lists` folder).

`censor_mat`: a .mat file containing the information of which runs of each subject have passed the censoring criterion. It is the output file of https://github.com/jingwei-li/Parcellate_ABCD_DCANpreproc/blob/main/compute_RSFC_with_censor.m

`fsLR_file_ls`: fullpath to the output file list.

## Step 2.