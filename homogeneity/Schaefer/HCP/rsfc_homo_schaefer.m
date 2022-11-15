function homo_out = rsfc_homo_schaefer(scale, subj_ls, HCP_dir, outname)

% homo_out = rsfc_homo_schaefer(scale, subj_ls, outname)
% 
% Calculate resting-state functional connectivity homogeneity of the Schaefer 
% parcellation using the HCP dataset.
% Please install the CBIG github repo correctly to run this script:
% https://github.com/ThomasYeoLab/CBIG
%
% Inputs:
%   - scale
%     The granularity of Schaefer parcellation, e.g. 400
%   - subj_ls
%     Subject list. E.g. the list of randomly selected AA/WA.
%   - HCP_dir
%     The datalad directory of HCP dataset.
%   - outname
%     Output .mat filename.
%

repo_path = dirname(dirname(dirname(dirname(mfilename('fullpath')))));
addpath(fullfile(repo_path, 'external', 'CBIG'))

start_dir = pwd;
%% load parcellation
parc_dir = '/data/project/parcellate_ABCD_preprocessed/data/SchaeferParcellations/HCP/fslr32k/cifti';
if(~ischar(scale))
    scale = num2str(scale);
end
parc_name = fullfile(parc_dir, ['Schaefer2018_' scale 'Parcels_17Networks_order.dlabel.nii']);
parcellation = ft_read_cifti(parc_name, 'mapname', 'array');

%% process parcellation labels
N_ver = 32492;  % #vertices per hemisphere
lh_labels = parcellation.dlabel(1:N_ver);
rh_labels = parcellation.dlabel(N_ver+1:end);
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
cd(fullfile(HCP_dir, 'HCP1200'))
homo_out = zeros(length(subjects), 1);
for i = 1:length(subjects)
    s = subjects{i};
    fprintf('Subject: %s\n', s);
    count = 0;

    system(sprintf('datalad get -n %s', s));
    cd(fullfile(s, 'MNINonLinear'))
    system('datalad get -n .');
    if(~exist('Results', 'dir'))
        error('\t This subject does not have any resting-state fMRI data. Check your subject list.\n')
    end
    cd('Results')
    [~, msg] = system('find . -maxdepth 1 -type d -name "rfMRI*" -print0 | sort -z | xargs -r0');
    if(isempty(msg))
        error('\t This subject does not have any resting-state fMRI data. Check your subject list.\n')
    end

    runs = strsplit(msg);
    for j = 1:length(runs)
        if(~isempty(runs{j}))
            if(~any(strcmp({'rfMRI_REST1_LR', 'rfMRI_REST1_RL', 'rfMRI_REST2_LR', 'rfMRI_REST2_RL'}, basename(runs{j}))))
                warning('%s is not a 3T resting-state run.', runs{j})
                continue
            end

            %% read current run timeseries
            cd(runs{j})
            fname = [runs{j} '_Atlas_MSMAll_hp2000_clean.dtseries.nii'];
            system(sprintf('datalad get %s', fname));
            [~, vol, ~] = read_fmri(fname);
            vol((2*N_ver+1):end,:)=[];
            all_nan=find(isnan(mean(vol,2))==1); % nan vertices

            %% homogeneity for current run
            labels_size = [];
            for c = 1:max(labels)      
                index_cluster = find(labels==c);
                index_cluster = setdiff(index_cluster, all_nan);
                a = vol(index_cluster,:)';  % #timepoints x #vertices
                a_std = std(a,0,1);
                idx_zerostd = find(a_std == 0);
                if(~isempty(idx_zerostd))
                    warning('\t run %s: %d vertices with label %d have a constant signal.\n', ...
                        runs{j}, length(idx_zerostd), c)
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
                
            end
            curr_homo=sum(labels_size(i,:)*homo_parc)/sum(labels_size(i,:));
            
            %average across scans
            homo_out(i,1) =  homo_out(i,1) + curr_homo;
            count = count + 1;
            cd ..
        end
    end

    homo_out(i,1) = homo_out(i,1) / count;

    cd(fullfile(HCP_dir, 'HCP1200'))
    system(sprintf('datalad uninstall %s --recursive', s));
end

outdir = fileparts(outname);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outname, 'homo_out', '-v7.3')
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