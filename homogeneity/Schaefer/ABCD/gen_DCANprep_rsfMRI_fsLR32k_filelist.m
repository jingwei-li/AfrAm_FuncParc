function gen_DCANprep_rsfMRI_fsLR32k_filelist(data_dir, subj_ls, censor_mat, fsLR_file_ls)

% gen_DCANprep_rsfMRI_fsLR32k_filelist(subj_ls, censor_mat, fsLR_file_ls)
% 
% 
% Input:
%   - data_dir
%     The top-level directory containing the DCAN lab preprocessed ABCD data.
%   - subj_ls
%     A list of subjects of interest, which should be a subset of `subjects_pass` (see below).
%   - censor_mat
%     A .mat file containing the information of which runs of each subject have passed
%     the censoring criterion. It is the output file of 
%     https://github.com/jingwei-li/Parcellate_ABCD_DCANpreproc/blob/main/compute_RSFC_with_censor.m
%     It should contain at leaset the following variables:
%     `subjects`, a cell, list of subjects before censoring;
%     `subjects_pass`, a cell, list of subjects after censoring;
%     `pass_runs`, a cell with same length as `subjects`, which runs passed censoring criterion for each subject.
%
% Output:
%   - fsLR_file_ls
%     Path to the output file list. In this list, each line corresponds to a subject, the filenames of each run's 
%     timeseries are separated by a space in the same line.

proj_dir = '/data/project/AfrAm_FuncParc';
repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))
start_dir = pwd;
ses = 'ses-baselineYear1Arm1';

if(isempty(data_dir))
    data_dir = fullfile(proj_dir, 'data', 'datasets', 'inm7_superds', ...
        'original', 'abcd', 'derivatives', 'abcd-hcp-pipeline');
end
fprintf('data_dir = %s\n', data_dir)

soi = CBIG_text2cell(subj_ls);
load(censor_mat)
[~,~,idx1] = intersect(soi, subjects_pass, 'stable');
[~,~,idx2] = intersect(subjects_pass, subjects, 'stable');
fnames = cell(length(soi), 1);
for i = 1:length(soi)
    s = soi{i};
    runs = pass_runs{idx2(idx1(i))};
    for j = 1:length(runs)
        dt = [s '_' ses '_task-rest_' runs{j} '_bold_timeseries.dtseries.nii'];
        fnames{i} = [fnames{i} ' ' fullfile(data_dir, s, ses, 'func', dt)];
    end
end
CBIG_cell2text(fnames, fsLR_file_ls)

rmpath(fullfile(repo_path, 'external', 'CBIG'))

end
