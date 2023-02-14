function compute_RSFC_with_censor(scale, subj_ls, roi_ts_dir, censor_mat)
% compute_RSFC_with_censor(scale, subj_ls, roi_ts_dir, out_censor_mat)
%
% Compute ROI-to-ROI functional connectivity. The ROIs are defined by a combination of
% cortical Schaefer's parcellation and subcortical Tian's parcellation at a certain scale.
% For each subject, the computed functional connectivity will be saved in each subject folder
% under `roi_ts_dir`, following BIDS format.
%
% Input:
% - scale: choose from 1 to 10. 
%          Schaefer parcellation with (scale * 100) areas
%
% - subj_ls
%   Subject list who have preprocessed resting-state fMRI data.
%
% - roi_ts_dir
%   Full-path directory containing the parcellated timeseries (output folder of `extract_rest_timeseries_*.m`).
%
% - out_censor_mat
%   Output .mat filename containing which subjects, which runs passed motion censoring, which are not, and which
%   runs only have fsLR32k space files but not MNI space files.
%

start_dir = pwd;
proj_dir = '/data/project/parcellate_ABCD_preprocessed';
data_dir = fullfile(proj_dir, 'data', 'inm7-superds', 'original', 'abcd', 'derivatives', 'abcd-hcp-pipeline');

subjects = text2cell(subj_ls);
ses = 'ses-baselineYear1Arm1';
FD_threshold = 0.3;

Schaefer_res = 100*scale;
censor = load(censor_mat);
[~,~,idx] = intersect(subjects, censor.subjects, 'stable');

for i = 1:length(subjects)
    s = subjects{i};
    fprintf('%s\n', s)
    pass_runs = censor.pass_runs{idx(i)};

    cd(fullfile(roi_ts_dir, s, ses, 'func'))
    
    if(length(pass_runs)>0)
        cd(data_dir)
        system(sprintf('datalad get -n %s', s));
        system(sprintf('git -C %s config --local --add remote.datalad.annex-ignore true', s));
        
        for j = 1:length(pass_runs)
            runnum = pass_runs{j};
            out_name = fullfile(roi_ts_dir, s, ses, 'func', [s '_' ses '_task-rest_' runnum ...
                '_RSFC_Schaefer' num2str(Schaefer_res) '.mat']);
            
            cd(fullfile(data_dir, s, ses, 'func'))
            mt_tsv = [s '_' ses '_task-rest_' runnum '_desc-includingFD_motion.tsv'];
            system(sprintf('datalad get -s inm7-storage %s', mt_tsv));
            % for some run, the "desc-includingFD_motion.tsv" file doesn't exist
            % calculate FD from 6 motion parameters
            if(~exist(mt_tsv))
                mt_tsv = [s '_' ses '_task-rest_' runnum '_motion.tsv'];
                system(sprintf('datalad get -s inm7-storage %s', mt_tsv));
                system(sprintf('cat %s | tr -s ''([\t]+)'' '','' > tmp.tsv', mt_tsv)) % replace multiple \t to a single comma
                % add comma to the beginning of the first line (because there are extra tabs from line 2 in the original file); 
                % remove the first comma of each line (remove the extra tab); 
                % remove the last comma of each line (because there are extra tabs at the end of each line in the original file)
                system('echo ",$(cat tmp.tsv)" > tmp2.tsv; cut -c 2- < tmp2.tsv > tmp3.tsv; sed -i ''s/.$//'' tmp3.tsv')
                mt = tdfread('tmp3.tsv', ',')
                % for some run, there isn't extra tab at the end of first line. Therefore the previous step would remove the 't'
                if(~isfield(mt, 'RotZDt'))
                    [mt.RotZDt] = mt.RotZD;
                    mt = rmfield(mt, 'RotZD');
                end
                mt.framewise_displacement = abs(mt.XDt) + abs(mt.YDt) + abs(mt.ZDt) + 50*pi/360 * (abs(mt.RotXDt) + abs(mt.RotYDt) + abs(mt.RotZDt));
            else
                mt = tdfread(mt_tsv, ' ');
            end
            
            cd(fullfile(roi_ts_dir, s, ses, 'func'))

            FD_outlier = mt.framewise_displacement>FD_threshold;
            % compute FC for current run with censoring
            ts_cort = load([s '_' ses '_task-rest_' runnum '_bold_atlas-Schaefer400_timeseries.mat']);
            corr_mat = FC_per_run(ts_cort.pts, FD_outlier);
            save(out_name, 'corr_mat')
            
        end

        
    end

end



end



function cell_array = text2cell(text_file)
    num_lines = 0;
    fid = fopen(text_file);
    while (~feof(fid))
        num_lines = num_lines + 1;
        cell_array{num_lines} = fgetl(fid);
    end
    fclose(fid);

end

function cell2text(cell_var, filename)

    fid = fopen(filename, 'w');
    formatSpec = '%s\n';
    
    for row = 1:length(cell_var);
        fprintf(fid, formatSpec, cell_var{row});
    end
    
    fclose(fid);
end

function corr_mat = my_corr(X, Y)

    % Calculate correlation matrix between each column of two matrix.
    % 
    % 	corr_mat = my_corr(X, Y)
    % 	Input:
    % 		X: D x N1 matrix
    % 		Y: D x N2 matrix
    % 	Output:
    % 		corr_mat: N1 x N2 matrix    
    
    X = bsxfun(@minus, X, mean(X, 1));
    X = bsxfun(@times, X, 1./sqrt(sum(X.^2, 1)));
    
    Y = bsxfun(@minus, Y, mean(Y, 1));
    Y = bsxfun(@times, Y, 1./sqrt(sum(Y.^2, 1)));
    
    corr_mat = X' * Y;
end

function FC = FC_per_run(ts_cort, FD_outlier)

    % ts_cort: Schaefer-parcellated timeseries from cortex. #ROI_1 x T matrix
    % FD_outlier: 0/1 vector with length = T

    % cortical to cortical
    FC = my_corr(ts_cort(:,FD_outlier==0)', ts_cort(:,FD_outlier==0)');
    %subcort = my_corr(ts_subcort(:,FD_outlier==0)', ts_subcort(:,FD_outlier==0)');
    %cort_subcort = my_corr(ts_cort(:,FD_outlier==0)', ts_subcort(:, FD_outlier==0)');
    %FC = [[cort cort_subcort]; [cort_subcort' subcort]];
end