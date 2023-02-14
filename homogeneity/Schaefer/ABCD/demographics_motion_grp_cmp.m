function demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, ABCD_dir, censor_mat, demo_csv, hand_csv, site_csv, outmat)

% demographics_motion_grp_cmp(grp1_subj_ls, grp2_subj_ls, ABCD_dir, censor_mat, demo_csv, hand_csv, outmat)
%
% Inputs:
%   - grp1_subj_ls
%     Subject list of group 1.
%
%   - grp2_subj_ls
%     Subject list of group 2.
%
%   - ABCD_dir
%     The local directory of ABCD datalad repository (DCAN-lab preprocessed data).
%     Default: /data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/derivatives/abcd-hcp-pipeline
%
%   - censor_mat
%     A .mat file containing the information of which runs of each subject have passed
%     the censoring criterion. It is the output file of 
%     https://github.com/jingwei-li/Parcellate_ABCD_DCANpreproc/blob/main/compute_RSFC_with_censor.m
%     It should contain at leaset the following variables:
%     `subjects`, a cell, list of subjects before censoring;
%     `subjects_pass`, a cell, list of subjects after censoring;
%     `pass_runs`, a cell with same length as `subjects`, which runs passed censoring criterion for each subject.
%
%   - demo_csv
%     The CSV file containing demographic (age, sex, race/ethnicity) information. (absolute path).
%     Default: /data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/acspsw03.txt
%
%   - hand_csv
%     The CSV file containing handedness information. (absolute path).
%     Default: /data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_ehis01.txt
%
%   - site_csv
%     The CSV file containing site information (absolute path).
%     Default: /data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_lt01.txt
%
%   - outmat
%     Output .mat file.
%

if(isempty(ABCD_dir) || strcmpi(ABCD_dir, 'none'))
    ABCD_dir = '/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/derivatives/abcd-hcp-pipeline';
end
if(isempty(demo_csv) || strcmpi(demo_csv, 'none'))
    demo_csv = '/data/project/template_t1/data/ABCD_datalad/inm7-superds/original/abcd/phenotype/phenotype/acspsw03.txt';
end
if(isempty(hand_csv) || strcmpi(hand_csv, 'none'))
    hand_csv = '/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_ehis01.txt';
end
if(isempty(site_csv) || strcmpi(site_csv, 'none'))
    site_csv = '/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype/abcd_lt01.txt';
end

start_dir = pwd;

[subjects{1}, n_grp1] = CBIG_text2cell(grp1_subj_ls);
[subjects{2}, n_grp2] = CBIG_text2cell(grp2_subj_ls);
if(n_grp1 ~= n_grp2)
    error('Sample size of the two groups is not the same.\n')
end
censor = load(censor_mat);

%% age, sex, handedness, and site
for g = 1:2
    for i = 1:n_grp1
        subjects_csv{g}{i} = ['NDAR_' subjects{g}{i}(9:end)];
    end
end

d_demo = readtable(demo_csv, 'Delimiter', '\t');
d_hand = readtable(hand_csv, 'Delimiter', '\t');
d_site = readtable(site_csv, 'Delimiter', '\t');

age = nan(n_grp1, 2);
sex = nan(n_grp1, 2);
handedness = nan(n_grp1, 2);
site = nan(n_grp1, 2);
info = '1=right handed; 2=left handed; 3=mixed handed';

for g = 1:2
    base_idx = find(strcmp(d_demo.eventname, 'baseline_year_1_arm_1'));
    [intersect_subj, idx1, idx] = intersect(subjects_csv{g}, d_demo.subjectkey(base_idx), 'stable');

    curr_age = d_demo.interview_age(base_idx(idx));
    age(:,g) = cellfun(@str2num, curr_age);

    curr_sex = d_demo.sex(base_idx(idx));
    sex(strcmp(curr_sex, 'F'), g) = 0;
    sex(strcmp(curr_sex, 'M'), g) = 1;

    base_idx = find(strcmp(d_hand.eventname, 'baseline_year_1_arm_1'));
    [~, ~, idx] = intersect(subjects_csv{g}, d_hand.subjectkey(base_idx), 'stable');
    curr_hand = d_hand.ehi_y_ss_scoreb(base_idx(idx));
    handedness(:,g) = cellfun(@str2num, curr_hand);

    base_idx = find(strcmp(d_site.eventname, 'baseline_year_1_arm_1'));
    [~, ~, idx] = intersect(subjects_csv{g}, d_site.subjectkey(base_idx), 'stable');
    curr_site = d_site.site_id_l(base_idx(idx));
    erase(curr_site, 'site')
    site(:,g) = cellfun(@str2num, erase(curr_site, 'site'));
end

%% head motion
ses = 'ses-baselineYear1Arm1';
FD = nan(n_grp1, 2);
for g = 1:2
    for i = 1:n_grp1
        curr_FD = [];
        s = subjects{g}{i};
        cd(ABCD_dir);
        system(sprintf('datalad get -n %s', s));
        system(sprintf('git -C %s config --local --add remote.datalad.annex-ignore true', s));

        cd(fullfile(s, ses, 'func'));
        idx = strcmp(censor.subjects, s);
        runs = censor.pass_runs{idx};
        for j = 1:length(runs)
            run = runs{j};
            mt_tsv = [s '_' ses '_task-rest_' run '_desc-includingFD_motion.tsv'];
            system(sprintf('datalad get -s inm7-storage %s', mt_tsv));
            % for some run, the "desc-includingFD_motion.tsv" file doesn't exist
            % calculate FD from 6 motion parameters
            if(~exist(mt_tsv))
                mt_tsv = [s '_' ses '_task-rest_' run '_motion.tsv'];
                system(sprintf('datalad get -s inm7-storage %s', mt_tsv));
                system(sprintf('cat %s | tr -s ''([\t]+)'' '','' > tmp.tsv', mt_tsv)) % replace multiple \t to a single comma
                % add comma to the beginning of the first line (because there are extra tabs from line 2 in the original file); 
                % remove the first comma of each line (remove the extra tab); 
                % remove the last comma of each line (because there are extra tabs at the end of each line in the original file)
                system('echo ",$(cat tmp.tsv)" > tmp2.tsv; cut -c 2- < tmp2.tsv > tmp3.tsv; sed -i ''s/.$//'' tmp3.tsv')
                mt = tdfread('tmp3.tsv', ',')
                % for some run, there isn't extra tab at the end of first line. Therefore the previous step would remove the 't'
                if(~isfield(mt, 'RotZDt'))
                    [mt.RotZDt] = mt.RotZD;
                    mt = rmfield(mt, 'RotZD');
                end
                mt.framewise_displacement = abs(mt.XDt) + abs(mt.YDt) + abs(mt.ZDt) + 50*pi/360 * (abs(mt.RotXDt) + abs(mt.RotYDt) + abs(mt.RotZDt));
            else
                mt = tdfread(mt_tsv, ' ');
            end
            curr_FD = [curr_FD mean(mt.framewise_displacement)];
        end
        FD(i,g) = mean(curr_FD);
        cd(ABCD_dir)
    end
end

cd(start_dir)
save(outmat, 'FD', 'sex', 'age', 'handedness', 'site', 'info')
    
end