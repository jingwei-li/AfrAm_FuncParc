function violin_rsfc_homo_schaefer(homo_grp1, homo_grp2, grp1_name, grp2_name, out_png)

% violin_rsfc_homo_schaefer(homo_mat, grp1_name, grp2_name, out_png)
%
% Create violin plot for comparing Schaefer parcellation homogeneity on two populations.
% 
% Input:
%   - homo_grp1
%     Homoeneity .mat file of group 1, generated by `rsfc_homo_schaefer.m`. It contains a variable
%     `homo_out`, which is a N x 1 vector, N is the number of subjects.
%
%   - homo_grp2
%     Homoeneity .mat file of group 2, generated by `rsfc_homo_schaefer.m`. It contains a variable
%     `homo_out`, which is a N x 1 vector, N is the number of subjects.
%
%   - grp1_name
%     The name of group 1. Used for the x-axis label in the plot.
%  
%   - grp2_name
%     The name of group 2. Used for the x-axis label in the plot.
%
%   - out_png
%     Output .png filename.
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(genpath(fullfile(repo_path, 'external', 'fig_util')))
grp1 = load(homo_grp1);
grp2 = load(homo_grp2);

%% find nan indices
nan1 = find(isnan(grp1.homo_out));
nan2 = find(isnan(grp2.homo_out));
nan_idx = union(nan1, nan2)
if(~isempty(nan_idx))
    grp1.homo_out(nan_idx) = [];
    grp2.homo_out(nan_idx) = [];
end

[h, p] = ttest(grp1.homo_out, grp2.homo_out);
f = figure('visible', 'off');
vio = violinplot([grp1.homo_out grp2.homo_out], [], [], 'ShowMean', true);
for i = 1:length(vio)
    vio(i).ViolinPlot.LineWidth = 2;
    vio(i).ScatterPlot.SizeData = 12;
    vio(i).MedianPlot.SizeData = 18;
end
yl = ylabel('RSFC homogeneity');
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'xticklabel', {grp1_name grp2_name}, 'fontsize', 16, 'linewidth', 2);
set(gca, 'tickdir', 'out', 'box', 'off')

txt = sprintf('p = %f', p);
text(1.2, max(max([grp1.homo_out grp2.homo_out])), txt, 'fontsize', 16)

outdir = fileparts(out_png);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
export_fig(out_png, '-png', '-nofontswap', '-a1');
close

rmpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

end