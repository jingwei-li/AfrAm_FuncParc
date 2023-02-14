function plot_test_demographics_motion_diff(in_mat, grp1_name, grp2_name, fig_dir)

% plot_test_demographics_motion_diff(in_mat, grp1_name, grp2_name, fig_dir)
%
% Create histograms for FD, DVARS, age, sex, and handedness of the two groups of interest.
% Perform K-S test on the group differences of each variable.
%
% Inputs:
%   - in_mat
%     Input .mat file. It should be the output file of `demographics_motion_grp_cmp.m`.
%     It should contain variables 'FD', 'age', 'sex', 'handedness'.
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
hist(age, 20);
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

%% sex
f = figure('visible', 'off');
hist(sex, 2);
[counts, centers] = hist(sex, 2);
xl = xlabel('Sex');
set(gca, 'xtick', centers, 'xticklabel', {'F', 'M'})
set(xl, 'fontsize', 16, 'linewidth', 2)
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
centers = [1 2 3];
hist(handedness, centers);
xl = xlabel('Handedness');
set(gca, 'xtick', centers, 'xticklabel', {'R', 'L', 'Mix'})
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

%% site
f = figure('visible', 'off');
set(gcf, 'position', [0 0 800 400])
hist(site, unique(site(:)));
[counts, centers] = hist(site, unique(site(:)));
xl = xlabel('Site');
uq_site = num2str(unique(site(:)));
xtl = cellstr(uq_site);
set(gca, 'xtick', centers, 'xticklabel', xtl )
set(xl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 15)
l = legend({grp1_name grp2_name}, 'location', 'best');
set(l, 'fontsize', 16, 'linewidth', 2)

[H, p_site, ksstat] = kstest2(site(:,1), site(:,2));
txt = sprintf('p (KS) = %f', p_site);
title(txt, 'fontsize', 16);
outname = fullfile(fig_dir, 'Site.png');
export_fig(outname, '-png', '-nofontswap', '-a1');
close

rmpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

end