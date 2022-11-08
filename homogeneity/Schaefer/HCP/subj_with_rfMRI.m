function subj_with_rfMRI(HCP_dir, out_dir)

% subj_with_rfMRI(HCP_dir, out_dir)
%
% Obtain the list of subjects who has at leat one run of rfMRI preprocessed by ICA-FIX.
%
% Inputs:
%   - HCP_dir
%     The datalad directory of HCP dataset.
%   - out_dir
%     Full-path directory of output lists.
%
repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))

start_dir = pwd;
cd(fullfile(HCP_dir, 'HCP1200'))
full_subj_ls = fullfile(out_dir, 'subjects.txt');
system(['find . -maxdepth 1 -type d -regex ''\.\/[0-9]+'' -exec basename {} \; > ' full_subj_ls])
system(sprintf('sort -o %s %s', full_subj_ls, full_subj_ls))

subjects = CBIG_text2cell(fullfile(out_dir, 'subjects.txt'))
subj_rf = {};
for i = 1:length(subjects)
    s = subjects{i};
    system(sprintf('datalad get -n %s', s));
    system(sprintf('git -C %s config --local --add remote.datalad.annex-ignore true', s));
    cd(fullfile(s, 'MNINonLinear'))
    system('datalad get -n .');
    system('git -C . config --local --add remote.datalad.annex-ignore true');
    if(exist('Results', 'dir'))
        cd('Results')
        [~, msg] = system('find . -maxdepth 1 -type d -name "rfMRI*" -print0 | sort -z | xargs -r0');
        if(~isempty(msg))
            subj_rf = [subj_rf {s}];
        end
    end
    cd(fullfile(HCP_dir, 'HCP1200'))
    system(sprintf('datalad uninstall %s --recursive', s));
end
CBIG_cell2text(subj_rf, fullfile(out_dir, 'subject_rfMRI.txt'))

cd(start_dir)
rmpath(fullfile(repo_path, 'external', 'CBIG'))

end