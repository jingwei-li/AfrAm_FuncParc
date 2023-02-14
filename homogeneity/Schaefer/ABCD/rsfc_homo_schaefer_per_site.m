function homo_out = rsfc_homo_schaefer(scale, fsLR_ls, outname)

% homo_out = rsfc_homo_schaefer(parcellation, AA_ls, WA_ls)
%
% Calculate resting-state functional connectivity homogeneity of the Schaefer 
% parcellation, for two lists of African Americans and white Americans respectively,
% from the ABCD dataset.
% Please install the CBIG github repo correctly to run this script:
% https://github.com/ThomasYeoLab/CBIG
%
% Input:
%   - 
%     

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
lh_avg_mesh=CBIG_read_fslr_surface('lh','fs_LR_32k','inflated');
rh_avg_mesh=CBIG_read_fslr_surface('rh','fs_LR_32k','inflated');

filename = CBIG_text2cell(fsLR_ls);
homo_out = zeros(length(filename), 1);

num_subs = length(filename);
for k = 1:num_subs
    fprintf('%dth subject\n', k)
    count = 0;
    filename{k}
    curr_filename = textscan(filename{k}, '%s');
    curr_filename = curr_filename{1}; % a cell of size (#runs x 1) for subject k in the first list
    num_scans = length(curr_filename);

    for i=1:num_scans       
        if (~isnan(curr_filename{i}))
            if(~isempty(curr_filename{i}))
                input = curr_filename{i};
                fprintf('filename: %s \n', input);

                %% datalad get data
                [dir1, base, ext] = fileparts(input);
                [dir2, modal, ~] = fileparts(dir1);
                [dir3, ses, ~] = fileparts(dir2);
                [data_dir, s, ~] = fileparts(dir3);
                cd(data_dir)
                system('datalad get -n .');
                system(sprintf('datalad get -n %s', s));
                system(sprintf('git -C %s config --local --add remote.datalad.annex-ignore true', s));
                cd(fullfile(data_dir, s, ses, modal))
                system(sprintf('datalad get -s inm7-storage %s', [base ext]));

                %% read data
                [~, vol, ~] = read_fmri(input);
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
                        warning('%dth subject, run %d: %d vertices with label %d have a constant signal.\n', ...
                            k, i, length(idx_zerostd), c)
                        a(:,idx_zerostd) = [];
                        index_cluster(idx_zerostd) = [];
                    end
                    labels_size(k,c) = length(index_cluster);
                        
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
                curr_homo=sum(labels_size(k,:)*homo_parc)/sum(labels_size(k,:));
                    
                %average across scans
                homo_out(k,1) =  homo_out(k,1) + curr_homo;
                count = count + 1;
            end
        end
    end

    homo_out(k,1) = homo_out(k,1) / count;

    cd(data_dir)
    system(sprintf('datalad uninstall %s', s));
end


outdir = fileparts(outname);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outname, 'homo_out', '-v7.3')
cd(start_dir)

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