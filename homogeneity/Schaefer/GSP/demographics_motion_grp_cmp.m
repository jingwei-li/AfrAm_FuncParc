function demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, data_dir, demo_csv, outmat)

% demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, data_dir, demo_csv, outmat)
%
% Compare demographics and head motion between two groups of GSP subjects (same sample size).
%
% Inputs:
%   - grp1_subj_ls
%     Full path of the subject list of group 1.
%
%   - grp2_subj_ls
%     Full path of the subject list of group 2.
%
%   - data_dir
%     Local datalad repository which contains the preprocessed GSP data.
%     Head motion will be read from the confound file in each subject folder.
%
%   - demo_csv
%     The csv file which contains demographic information.
%
%   - outmat
%     Output .mat filename.
%

start_dir = pwd;
[subjects{1}, n_grp1] = CBIG_text2cell(grp1_subj_ls);
[subjects{2}, n_grp2] = CBIG_text2cell(grp2_subj_ls);
if(n_grp1 ~= n_grp2)
    error('Sample size of the two groups should be the same.')
end

%% read age, sex, handedness
headers_str = {'Sex', 'Hand'};
headers_num = {'Age_Bin'};
for g = 1:2
    for i = 1:n_grp1
        subjects_csv{g}{i} = ['S'  subjects{g}{i}(2:3) subjects{g}{i}(5:end)  '_S1'];
    end
end
subjects_csv{1}

d = readtable(demo_csv);
d.Subject_ID
age = nan(n_grp1, 2); sex = nan(n_grp1, 2); hand = nan(n_grp1, 2);
for g = 1:2
    [~,~,idx] = intersect(subjects_csv{g}, d.Subject_ID, 'stable');
    curr_sex = d.Sex(idx);
    curr_hand = d.Hand(idx);
    age(:,g) = d.Age_Bin(idx);
    sex(strcmp(curr_sex, 'F'), g) = 0; % female - 0
    sex(strcmp(curr_sex, 'M'), g) = 1; % male - 1
    hand(strcmp(curr_hand, 'RHT'), g) = 0; % right-handed - 0
    hand(strcmp(curr_hand, 'LFT'), g) = 1; % left-handed - 1
end

info.sex = 'female: 0; male: 1';
info.hand = 'right-handed: 0; left-handed: 1';

%% read head motion
cd(data_dir)
FD = nan(n_grp1, 2);
DVARS = nan(n_grp1, 2);
for g = 1:2
    fprintf('Group 1: \n')
    for i = 1:n_grp1
        s = subjects{g}{i};
        fprintf('%s\n', s)

        cd(fullfile(s, 'ses-01'))
        conf_file = ['Confounds_' s '_ses-01.mat'];
        system(sprintf('datalad get -s inm7-storage %s', conf_file))

        conf = load(conf_file);
        FD(i, g) = conf.FD;
        DVARS(i, g) = mean(conf.DVARS);

        %system(sprintf('datalad drop %s', conf_file))
        cd ../..
    end
end


save(outmat, 'FD', 'DVARS', 'age', 'sex', 'hand', 'info');
    
end