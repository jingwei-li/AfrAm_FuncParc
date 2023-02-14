function demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, HCP_dir, unrestrict_csv, restrict_csv, outmat)

% demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, HCP_dir, unrestrict_csv, restrict_csv, outmat)
%
% Compare the demographics and head motion between two groups in the HCP-YA dataset.
%
% Inputs:
%   - grp1_subj_ls
%     Subject list of group 1.
%
%   - grp2_subj_ls
%     Subject list of group 2.
%
%   - HCP_dir
%     The local directory of the HCP-YA datalad repository. Head motion needs to be read from this dataset.
%
%   - unrestrict_csv
%     Path to the HCP-YA unrestricted CSV file.
% 
%   - restrict_csv
%     Path to the HCP-YA restricted CSV file.
%
%   - outmat
%     Output .mat file.
%

start_dir = pwd;

[subjects{1}, n_grp1] = CBIG_text2cell(grp1_subj_ls);
[subjects{2}, n_grp2] = CBIG_text2cell(grp2_subj_ls);
if(n_grp1 ~= n_grp2)
    error('Sample size of the two groups is not the same.\n')
end

%% age, sex, handedness
header_gender = 'Gender';
headers_num = {'Age_in_Yrs', 'Handedness'};
gender = nan(n_grp1, 2); age = nan(n_grp1, 2); handedness = nan(n_grp1, 2);
for g = 1:2
    [curr_gender] = CBIG_parse_delimited_txtfile(unrestrict_csv, {header_gender}, [], 'Subject', subjects{g});
    gender(strcmp(curr_gender, 'F'), g) = 0;
    gender(strcmp(curr_gender, 'M'), g) = 1;

    [~, age_hand] = CBIG_parse_delimited_txtfile(restrict_csv, [], headers_num, 'Subject', subjects{g});
    age(:,g) = age_hand(:,1);
    handedness(:,g) = age_hand(:,2);
end

cd(fullfile(HCP_dir, 'HCP1200'))
runs = {'rfMRI_REST1_LR', 'rfMRI_REST1_RL', 'rfMRI_REST2_LR', 'rfMRI_REST2_RL'};
mt_file = 'Movement_RelativeRMS_mean.txt';
%% head motion
FD = nan(n_grp1, 2);
for g = 1:2
    for i = 1:n_grp1
        FD_sub = [];
        s = subjects{g}{i};
        %system(sprintf('datalad get -n %s', s));
        cd(fullfile(s, 'MNINonLinear'))
        %system('datalad get -n .')
        cd('Results')
        for j = 1:4
            run = runs{j};
            if(exist(run, 'dir'))
                cd(run)
                %system(sprintf('datalad get %s', mt_file));
                FD_sub = [FD_sub dlmread(mt_file)];
            end
        end
        FD(i, g) = mean(FD_sub);

        cd(fullfile(HCP_dir, 'HCP1200'))
        %system(sprintf('datalad uninstall %s --recursive', s));
    end
end



save(outmat, 'FD', 'gender', 'age', 'handedness')
    
end