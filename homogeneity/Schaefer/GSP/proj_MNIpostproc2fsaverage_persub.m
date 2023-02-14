function proj_MNIpostproc2fsaverage_persub(SID, MNI_dir, average)

% proj_MNIpostproc2fsaverage_persub(MNI_dir, outdir)
%
% This function assumes that the CBIG repository is correctly set up.
% (https://github.com/ThomasYeoLab/CBIG)
%
% Inputs:
%   - SID
%     Subject ID.
%   - MNI_dir
%     Directory of postprocessed data in MNI space.
%

MNI_fname = fullfile(MNI_dir, [SID '_ses01_postproc.nii.gz']);
mri = MRIread(MNI_fname);

if(~exist('average', 'var'))
    average = 'fsaverage6';
end
[lh_ts, rh_ts] = CBIG_ProjectMNI2fsaverage_Ants(mri, average);

if(~exist(fullfile(MNI_dir, 'surf')));
    mkdir(fullfile(MNI_dir, 'surf'));
end
%lh_fname = fullfile(MNI_dir, 'surf', ['lh.' SID '_ses01_postproc.mat']);
%rh_fname = fullfile(MNI_dir, 'surf', ['rh.' SID '_ses01_postproc.mat']);
%save(lh_fname, 'lh_ts', '-v7.3')
%save(rh_fname, 'rh_ts', '-v7.3')

lh_fname = fullfile(MNI_dir, 'surf', ['lh.' SID '_ses01_postproc.nii.gz']);
mri.vol = reshape(lh_ts', 6827, 3, 2, size(lh_ts,1));
MRIwrite(mri, lh_fname)
rh_fname = fullfile(MNI_dir, 'surf', ['rh.' SID '_ses01_postproc.nii.gz']);
mri.vol = reshape(rh_ts', 6827, 3, 2, size(rh_ts,1));
MRIwrite(mri, rh_fname)
    
end