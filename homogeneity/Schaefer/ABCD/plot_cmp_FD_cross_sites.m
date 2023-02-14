function plot_cmp_FD_cross_sites(site_ls, ABCD_dir, censor_mat, outmat, out_png)

% plot_cmp_FD_cross_sites(site_ls, ABCD_dir, censor_mat, out_png)
%
% Inputs:
%   - site_ls
%     A list which contains the paths of subject lists selected for each big site picked.
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
%   - outmat
%     Path of output .mat file.
%
%   - out_png
%     Path of output .png figure.
% 

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(genpath(fullfile(repo_path, 'external', 'fig_util')))
start_dir = pwd;

if(isempty(ABCD_dir) || strcmpi(ABCD_dir, 'none'))
    ABCD_dir = '/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/derivatives/abcd-hcp-pipeline';
end

subj_ls = CBIG_text2cell(site_ls);
subj_matched = cell(length(subj_ls), 1);
for i = 1:length(subj_ls)
    subj_matched{i} = CBIG_text2cell(subj_ls{i});
end
    
%% head motion
censor = load(censor_mat);
ses = 'ses-baselineYear1Arm1';
FD = nan(length(subj_matched{1}), length(subj_ls));
for g = 1:length(subj_ls)
    for i = 1:length(subj_matched{g})
        curr_FD = [];
        s = subj_matched{g}{i};
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

outdir = fileparts(outmat);
if(~exist(outdir, 'dir')) 
    mkdir(outdir);
end
save(outmat, 'FD')

%% plotting
sites = [];
for i = 1:length(subj_ls)
    substrings = strsplit(basename(subj_ls{i}), '_');
    curr_site = substrings(contains(substrings, 'site'));
    sites = [sites curr_site];
end

f = figure('visible', 'off');
vio = violinplot(FD, [], [], 'ShowMean', true);
for i = 1:length(vio)
    vio(i).ViolinPlot.LineWidth = 2;
    vio(i).ScatterPlot.SizeData = 12;
    vio(i).MedianPlot.SizeData = 18;
end
yl = ylabel('FD');
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'xticklabel', sites, 'fontsize', 16, 'linewidth', 2);
set(gca, 'tickdir', 'out', 'box', 'off')

outdir = fileparts(out_png);
if(~exist(outdir, 'dir')) 
    mkdir(outdir);
end
export_fig(out_png, '-png', '-nofontswap', '-a1');
close

cd(start_dir)
rmpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

end