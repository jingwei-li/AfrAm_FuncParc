function subj_with_rfMRI(GSP_dir, out_dir)

% subj_with_rfMRI(GSP_dir, out_dir)
%
% Collect the subjects with resting-state fMRI data after preprocessing.
% 
% Input:
%   - GSP_dir
%     The datalad directory of the GSP dataset.
%   - out_dir
%     Full-path directory of output lists.
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))

start_dir = pwd;
cd(GSP_dir)
full_subj_ls = fullfile(out_dir, 'subjects.txt');
if(~exist(out_dir, 'dir'))
    mkdir(out_dir)
end
system(['find . -maxdepth 1 -type d -regex ''\.\/sub-[0-9]+'' -exec basename {} \; > ' full_subj_ls])
system(sprintf('sort -o %s %s', full_subj_ls, full_subj_ls))

subjects = CBIG_text2cell(fullfile(out_dir, 'subjects.txt'))
subj_rf = {};
for i = 1:length(subjects)
    s = subjects{i};
    fprintf('%s\n', s)
    cd(s)
    if(exist('ses-01', 'dir'))
        cd('ses-01')
        flag_conf = system(sprintf('ls Confounds_%s_ses-01.mat', s));
        flag_mri = system(sprintf('ls w%s_ses-01.nii.gz', s));

        if(flag_conf == 0 && flag_mri == 0)
            subj_rf = [subj_rf {s}];
        end
    end
    cd ../..
end
CBIG_cell2text(subj_rf, fullfile(out_dir, 'subject_rfMRI.txt'))

cd(start_dir)
rmpath(fullfile(repo_path, 'external', 'CBIG'))
    
end