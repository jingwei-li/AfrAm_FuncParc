function ROI2ROI_RSFC(subj_ls, data_dir, outmat)

% ROI2ROI_RSFC(subj_ls, outmat)
%
% 

script_dir = dirname(mfilename('fullpath'));

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end

start_dir = pwd;
cd(data_dir);
subjects = CBIG_text2cell(subj_ls);
list = {};
for i = 1:length(subjects)
    s = subjects{i};
    cd(fullfile(s, 'ses-01'));
    fname = ['w' s '_ses-01.nii.gz'];
    if(~exist(fname, 'file'))
        system(sprintf('datalad get -s inm7-storage %s', fname))
    end
    list = [list {fullfile(data_dir, s, 'ses-01', fname)}];
    cd ../..
end
[~, subj_ls_base] = fileparts(subj_ls);
list_fname = fullfile(script_dir, 'lists', ['vol_' subj_ls_base '.txt']);
CBIG_cell2text(list, list_fname)

parc_dir = '/data/project/parcellate_ABCD_preprocessed/data/SchaeferParcellations/MNI';
scale = '400';
parc_name = fullfile(parc_dir, ['Schaefer2018_' scale 'Parcels_17Networks_order_FSLMNI152_2mm.nii.gz']);

CBIG_ComputeROIs2ROIsCorrelationMatrix(outmat, list_fname, list_fname, ...
    'NONE', parc_name, parc_name, 'NONE', 'NONE', 1, 1)
    
%for i = 1:length(subjects)
%    s = subjects{i};
%    cd(fullfile(s, 'ses-01'));
%    fname = ['w' s '_ses-01.nii.gz'];
%    system(sprintf('datalad drop %s', fname))
%end

end