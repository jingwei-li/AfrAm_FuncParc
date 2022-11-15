function postproc_fMRI_persub(indir, sub, outdir)

% postproc_fMRI_persub(sub, outdir)
%
% Input:
%   - indir
%     Full path of the datalad directory of the GSP dataset.
%
%   - sub: 
%     string, subject ID.
%
%   - outdir: 
%     string, full path of output directory.
%     Default: '/data/project/AfrAm_FuncParc/data/datasets/GSP_postproc'
%
%  Author: Jingwei Li, 11/11/2022
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))

start_dir = pwd;
cd(fullfile(indir, sub, 'ses-01'))
%% get datalad files
conf_file = ['Confounds_' sub '_ses-01.mat'];
mri_file = ['w' sub '_ses-01.nii.gz'];
system(sprintf('datalad get -s inm7-storage %s', conf_file))
system(sprintf('datalad get -s inm7-storage %s', mri_file))

%% load data
load(conf_file)
mri = MRIread(mri_file);
dim = size(mri.vol);
vol = reshape(mri.vol, prod(dim(1:3)), dim(4));

%% regression
tissue = gx2([2:4], :)';
tissue_deriv = [zeros(1, size(tissue,2)); diff(tissue)];
regressors = [reg(:, 9:32) tissue tissue_deriv];
[resid, ~, ~, ~] = CBIG_glm_regress_matrix(vol', regressors, 1, []); 
resid = reshape(resid', dim); 

%% saving
if(~exist(outdir, 'dir')) mkdir(outdir); end
mri.vol = resid;
outname = fullfile(outdir, [sub '_ses01_postproc.nii.gz']);
MRIwrite(mri, outname)

%% drop datalad files
system(sprintf('datalad drop %s', conf_file))
system(sprintf('datalad drop %s', mri_file))
cd(start_dir)
    
end