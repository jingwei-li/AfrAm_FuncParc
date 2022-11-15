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
%     The directory to the postprocessed GSP data.
%   - outname
%     Output .mat filename.
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))

%% load parcellation
parc_dir = '/data/project/parcellate_ABCD_preprocessed/data/SchaeferParcellations/FreeSurfer5.3/fsaverage6/label';
if(~ischar(scale))
    scale = num2str(scale);
end
lh_parc_name = fullfile(parc_dir, ['lh.Schaefer2018_' scale 'Parcels_17Networks_order.annot']);
rh_parc_name = fullfile(parc_dir, ['rh.Schaefer2018_' scale 'Parcels_17Networks_order.annot']);
lh_labels = CBIG_read_annotation(lh_parc_name);
rh_labels = CBIG_read_annotation(rh_parc_name);

%% process parcellation labels
if(size(lh_labels,2)~=1)
    lh_labels = lh_labels';
end
if(size(rh_labels,2)~=1)
    rh_labels = rh_labels';
end

if(min(rh_labels(rh_labels~=0)) ~= max(lh_labels) + 1)
    rh_labels(rh_labels~=0) = rh_labels(rh_labels~=0) + max(lh_labels);
end
labels=[lh_labels;rh_labels];

%% load fMRI timeseries and calculate RSFC and homogeneity.
subjects = CBIG_text2cell(subj_ls);
homo_out = zeros(length(subjects), 1);
for i = 1:length(subjects)
    s = subjects{i};
    fprintf('Subject: %s\n', s);

    lh_fname = fullfile(data_dir, ['lh.' s '_ses01_postproc.mat']);
    rh_fname = fullfile(data_dir, ['rh.' s '_ses01_postproc.mat']);
    load(lh_fname)
    load(rh_fname)
    vol = cat(1, lh_ts', rh_ts');
    clear lh_ts rh_ts
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
        
        a = bsxfun(@minus, a, mean(a, 1));  % remove mean timeseries
        a = bsxfun(@times, a, 1./sqrt(sum(a.^2, 1)));  % normalize std of timeseries
        corr_mat = a' * a;  % correlation across timepoints

        %% compute homogeneity
        homo_parc(c,1)=(sum(sum(corr_mat))-size(corr_mat,1)) / ...
            (size(corr_mat,1) * (size(corr_mat,1)-1));
        if(size(corr_mat,1)==1||size(corr_mat,1)==0)
            homo_parc(c,1)=0;
        end
        fprintf('homo_parc(%d, 1) = %f \n', c, homo_parc(c,1))
        
    end
    homo_out(i,1) = sum(labels_size(i,:)*homo_parc)/sum(labels_size(i,:));
end

outdir = fileparts(outname);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outname, 'homo_out', '-v7.3')
rmpath(fullfile(repo_path, 'external', 'CBIG'))
    
end

