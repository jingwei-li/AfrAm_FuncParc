function plot_test_demographics_motion_diff(in_mat, grp1_name, grp2_name, fig_dir)

% plot_test_demographic_motion_diff(in_mat, grp1_name, grp2_name, fig_dir)
%
% Create histograms for FD, DVARS, age, sex, and handedness of the two groups of interest.
% Perform K-S test on the group differences of each variable.
%
% Inputs:
%   - in_mat
%     Input .mat file. It should be the output file of `demographics_motion_grp_cmp.m`.
%     It should contain variables 'FD', 'DVARS', 'age', 'sex', 'hand', 'info', where 'info'
%     describes how different categories in sex and handedness were mapped to different numbers.
%
%   - grp1_name
%     Name of group 1, which is used for plotting.
%
%   - grp2_name
%     Name of group 2, which is used for plotting.
%
%   - fig_dir
%     Output figure directory.
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

load(in_mat)
if(~exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end

%% FD
f = figure('visible', 'off');
hist(FD, 20);
yl = ylabel('FD');
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_FD, ksstat] = kstest2(FD(:,1), FD(:,2));
txt = sprintf('p (KS) = %f', p_FD);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'FD.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% DVARS
f = figure('visible', 'off');
hist(DVARS, 20);
yl = ylabel('DVARS');
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_DV, ksstat] = kstest2(DVARS(:,1), DVARS(:,2));
txt = sprintf('p (KS) = %f', p_DV);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'DVARS.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% age
f = figure('visible', 'off');
hist(age, unique(age(:)));
yl = ylabel('Age');
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_age, ksstat] = kstest2(age(:,1), age(:,2));
txt = sprintf('p (KS) = %f', p_age);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Age.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% sex
f = figure('visible', 'off');
hist(sex, 2);
[counts, centers] = hist(sex, 2);
yl = ylabel('Sex');
set(gca, 'xtick', centers, 'xticklabel', {'F', 'M'})
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 14)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_sex, ksstat] = kstest2(sex(:,1), sex(:,2));
txt = sprintf('p (KS) = %f', p_sex);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Sex.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% handedness
f = figure('visible', 'off');
hist(hand, 2);
[counts, centers] = hist(hand, 2);
yl = ylabel('Handedness');
set(gca, 'xtick', centers, 'xticklabel', {'R', 'L'})
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_hand, ksstat] = kstest2(hand(:,1), hand(:,2));
txt = sprintf('p (KS) = %f', p_hand);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Handedness.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

rmpath(genpath(fullfile(repo_path, 'external', 'fig_util')))
    
end