function plot_test_demographics_motion_diff(in_mat, grp1_name, grp2_name, fig_dir)

% plot_test_demographic_motion_diff(in_mat, grp1_name, grp2_name, fig_dir)
%
% Create histograms for FD, age, gender, and handedness of the two groups of interest.
% Perform K-S test on the group differences of each variable.
%
% Inputs:
%   - in_mat
%     Input .mat file. It should be the output file of `demographics_motion_grp_cmp.m`.
%
%   - grp1_name
%     Name of group 1, which is used for plotting.
%
%   - grp2_name
%     Name of group 2, which is used for plotting.
%
%   - fig_dir
%     Output figure directory.

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

load(in_mat)
if(~exist(fig_dir, 'dir'))
    mkdir(fig_dir);
end

%% FD
f = figure('visible', 'off');
hist(FD, 20);
xl = xlabel('FD');
set(xl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_FD, ksstat] = kstest2(FD(:,1), FD(:,2));
txt = sprintf('p (KS) = %f', p_FD);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'FD.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% age
f = figure('visible', 'off');
hist(age, unique(age(:)));
xl = xlabel('Age');
set(xl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_age, ksstat] = kstest2(age(:,1), age(:,2));
txt = sprintf('p (KS) = %f', p_age);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Age.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% gender
f = figure('visible', 'off');
hist(gender, 2);
[counts, centers] = hist(gender, 2);
xl = xlabel('Gender');
set(gca, 'xtick', centers, 'xticklabel', {'F', 'M'})
set(xl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 14)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_gender, ksstat] = kstest2(gender(:,1), gender(:,2));
txt = sprintf('p (KS) = %f', p_gender);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Gender.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

%% handedness
f = figure('visible', 'off');
hist(handedness, 20);
xl = xlabel('Handedness');
set(xl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_hand, ksstat] = kstest2(handedness(:,1), handedness(:,2));
txt = sprintf('p (KS) = %f', p_hand);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Handedness.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

rmpath(genpath(fullfile(repo_path, 'external', 'fig_util')))
    
end