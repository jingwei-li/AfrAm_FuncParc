function plot_cmp_rsfc_homo_cross_sites(homo_mat_ls, outfig, outstats)

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

%% collect homogeneity data and site names
homo_files = CBIG_text2cell(homo_mat_ls);
homo_all = [];
sites = [];
for i = 1:length(homo_files)
    load(homo_files{i});
    homo_all = [homo_all homo_out];

    substrings = strsplit(basename(homo_files{i}), '_');
    curr_site = substrings(contains(substrings, 'site'));
    sites = [sites curr_site];
end

%% violin plot
f = figure('visible', 'off');
vio = violinplot(homo_all, [], [], 'ShowMean', true);
for i = 1:length(vio)
    vio(i).ViolinPlot.LineWidth = 2;
    vio(i).ScatterPlot.SizeData = 12;
    vio(i).MedianPlot.SizeData = 18;
end
yl = ylabel('RSFC homogeneity');
set(yl, 'fontsize', 16, 'linewidth', 2)
set(gca, 'xticklabel', sites, 'fontsize', 16, 'linewidth', 2);
set(gca, 'tickdir', 'out', 'box', 'off')
outdir = fileparts(outfig);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
export_fig(outfig, '-png', '-nofontswap', '-a1');
close

%% statistical tests and multiple comparison correction
n_cmp = length(homo_files) * (length(homo_files)-1) / 2;
H = nan(n_cmp, 1); p = nan(n_cmp, 1);
count = 1;
for i  = 1:(length(homo_files)-1)
    for j = (i+1):length(homo_files)
        [H(count), p(count)] = ttest(homo_all(:,i), homo_all(j));
        field_name = [sites{i} '_vs_' sites{j}];
        stats.(field_name).H = H(count);
        stats.(field_name).p = p(count);
        count = count + 1;
    end
end
alpha = 0.05;
stats.FDR_ind = FDR(p, alpha);
outdir = fileparts(outstats);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outstats, 'stats')


rmpath(genpath(fullfile(repo_path, 'external', 'fig_util')))

end