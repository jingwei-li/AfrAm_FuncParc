function rsfc_homo_schaefer(scale, subj_ls, data_dir, outname)

% rsfc_homo_schaefer(scale, subj_ls, data_dir, outname)
%
% Compute RSFC homogeneity of Schaefer parcellation using the GSP dataset.
% Please install the CBIG github repo correctly to run this script:
% https://github.com/ThomasYeoLab/CBIG
%
% Input:
%   - scale
%     The granularity of Schaefer parcellation, e.g. 400
%   - subj_ls
%     Subject list. E.g. the list of randomly selected AA/WA.
%   - data_dir
%     The directory to the local datalad repository of the GSP dataset.
%   - outname
%     Output .mat filename.
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))

start_dir = pwd;
cd(data_dir);

%% load parcellation
parc_dir = '/data/project/parcellate_ABCD_preprocessed/data/SchaeferParcellations/MNI';
if(~ischar(scale))
    scale = num2str(scale);
end
parc_name = fullfile(parc_dir, ['Schaefer2018_' scale 'Parcels_17Networks_order_FSLMNI152_2mm.nii.gz']);
parcellation = MRIread(parc_name);
labels = parcellation.vol(:);

%% load fMRI timeseries and calculate RSFC and homogeneity.
subjects = CBIG_text2cell(subj_ls);
homo_out = zeros(length(subjects), 1);
for i = 1:length(subjects)
    s = subjects{i};
    fprintf('Subject: %s\n', s);

    cd(fullfile(s, 'ses-01'))
    fname = ['w' s '_ses-01.nii.gz'];
    system(sprintf('datalad get -s inm7-storage %s', fname))
    [~, vol, ~] = read_fmri(fname);
    all_nan=find(isnan(mean(vol,2))==1); % nan voxels

    %% homogeneity for current subject
    labels_size = [];
    for c = 1:max(labels)      
        index_cluster = find(labels==c);
        index_cluster = setdiff(index_cluster, all_nan);
        a = vol(index_cluster,:)';  % #timepoints x #vertices
        a_std = std(a,0,1);
        idx_zerostd = find(a_std == 0);
        if(~isempty(idx_zerostd))
            warning('\t %d vertices with label %d have a constant signal.\n', ...
                length(idx_zerostd), c)
            a(:,idx_zerostd) = [];
            index_cluster(idx_zerostd) = [];
        end
        labels_size(i,c) = length(index_cluster);
        
        a_mean = mean(a, 2);
        a_mean = a_mean - mean(a_mean);
        a_mean = a_mean ./ sqrt(sum(a_mean.^2, 1));

        a = bsxfun(@minus, a, mean(a, 1));  % remove mean timeseries
        a = bsxfun(@times, a, 1./sqrt(sum(a.^2, 1)));  % normalize std of timeseries
        
        corr_mat{i, c} = a' * a_mean;  % correlation across timepoints

        %% compute homogeneity
        %homo_parc(c,1)=(sum(sum(corr_mat))-size(corr_mat,1)) / ...
        %    (size(corr_mat,1) * (size(corr_mat,1)-1));
        %if(size(corr_mat,1)==1||size(corr_mat,1)==0)
        %    homo_parc(c,1)=0;
        %end
        %fprintf('homo_parc(%d, 1) = %f \n', c, homo_parc(c,1))
        
        %system(sprintf('datalad drop %s', fname))
        cd(data_dir);
    end
    %homo_out(i,1) = sum(labels_size(i,:)*homo_parc)/sum(labels_size(i,:));
end

outdir = fileparts(outname);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outname, 'corr_mat', '-v7.3')
cd(start_dir)
rmpath(fullfile(repo_path, 'external', 'CBIG'))
    
end


function [fmri, vol, vol_size] = read_fmri(fmri_name)

    % [fmri, vol] = read_fmri(fmri_name)
    % Given the name of functional MRI file (fmri_name), this function read in
    % the fmri structure and the content of signals (vol).
    % 
    % Input:
    %     - fmri_name:
    %       The full path of input file name.
    %
    % Output:
    %     - fmri:
    %       The structure read in by MRIread() or ft_read_cifti(). To save
    %       the memory, fmri.vol (for NIFTI) or fmri.dtseries (for CIFTI) is
    %       set to be empty after it is transfered to "vol".
    %
    %     - vol:
    %       A num_voxels x num_timepoints matrix which is the content of
    %       fmri.vol (for NIFTI) or fmri.dtseries (for CIFTI) after reshape.
    %
    %     - vol_size:
    %       The size of fmri.vol (NIFTI) or fmri.dtseries (CIFTI).
    
    if (isempty(strfind(fmri_name, '.dtseries.nii')))
        % if input file is NIFTI file
        fmri = MRIread(fmri_name);
        vol = single(fmri.vol);
        vol_size = size(vol);
        vol = reshape(vol, prod(vol_size(1:3)), prod(vol_size)/prod(vol_size(1:3)));
        fmri.vol = [];
    else
        % if input file is CIFTI file
        fmri = ft_read_cifti(fmri_name);
        vol = single(fmri.dtseries);
        vol_size = size(vol);
        fmri.dtseries = [];
    end
    
end
