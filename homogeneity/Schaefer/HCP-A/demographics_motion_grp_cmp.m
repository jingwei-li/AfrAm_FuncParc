function demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, HCPA_dir, outmat, age_sex_csv, hand_csv)

% demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, HCPA_dir, outmat, age_sex_csv, hand_csv)
%
% Inputs:
%   - grp1_subj_ls
%     Subject list of group 1.
%
%   - grp2_subj_ls
%     Subject list of group 2.
%
%   - HCPA_dir
%     The local directory of the HCP-Aging datalad repository.
%
%   - age_sex_csv
%     The csv file containing age and sex information.
%     Default: <HCPA_dir>/phenotype/ndar_subject01.txt
%
%   - hand_csv
%     The csv file containing the handedness information.
%     Default: <HCPA_dir>/phenotype/edinburgh_hand01.txt

start_dir = pwd;

[subjects{1}, n_grp1] = CBIG_text2cell(grp1_subj_ls);
[subjects{2}, n_grp2] = CBIG_text2cell(grp2_subj_ls);

%% age, sex, handedness
% remove '_V1_MR' from subject IDs because this string is not in the csv files.
for g = 1:2
    for i = 1:n_grp1
        subjects_csv{g}{i} = subjects{g}{i}(1:10);
    end
end

if(~exist('age_sex_csv', 'var') || isempty(age_sex_csv))
    age_sex_csv = fullfile(HCPA_dir, 'phenotype', 'ndar_subject01.txt');
end
if(~exist('hand_csv', 'var') || isempty(hand_csv))
    hand_csv = fullfile(HCPA_dir, 'phenotype', 'edinburgh_hand01.txt');
end

d_age_sex = readtable(age_sex_csv);
d_hand = readtable(hand_csv);

age = nan(n_grp1, 2);
sex = nan(n_grp1, 2);
handedness = nan(n_grp1, 2);
for g = 1:2
    [~, ~, idx] = intersect(subjects_csv{g}, d_age_sex.src_subject_id, 'stable');

    curr_age = d_age_sex.interview_age(idx);
    age(:,g) = cellfun(@str2num, curr_age);

    curr_sex = d_age_sex.sex(idx);
    sex(strcmp(curr_sex, 'F'), g) = 0;
    sex(strcmp(curr_sex, 'M'), g) = 1;

    [~, ~, idx] = intersect(subjects_csv{g}, d_hand.src_subject_id, 'stable');
    curr_hand = d_hand.hcp_handedness_score(idx);
    handedness(:,g) = cellfun(@str2num, curr_hand);
end

%% head motion
runs = {'rfMRI_REST1_AP', 'rfMRI_REST1_PA', 'rfMRI_REST2_AP', 'rfMRI_REST2_PA'};
cd(HCPA_dir);
FD = nan(n_grp1, 2);
for g = 1:2
    for i = 1:n_grp1
        s = subjects{g}{i};
        system(sprintf('datalad get -n %s', s));
        cd(fullfile(s, 'MNINonLinear'))
        system('datalad get -n .');
        cd('Results')

        curr_FD = [];
        for j = 1:4
            if(exist(runs{j}, 'dir'))
                cd(runs{j})
                FD_file = 'Movement_RelativeRMS_mean.txt';
                system(sprintf('datalad get -s inm7-storage %s', FD_file))
                curr_FD = [curr_FD dlmread(FD_file)];
                %system(sprintf('datalad drop %s', FD_file))
                cd ..
            end
        end
        FD(i, g) = mean(curr_FD);

        cd(HCPA_dir)
        %system(sprintf('datalad uninstall %s --recursive', s))
    end
end

save(outmat, 'FD', 'age', 'sex', 'handedness')
    
end