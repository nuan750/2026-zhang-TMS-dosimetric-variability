clc;
clear;
close all;

% This script extracts gray matter magnE percentiles for both C3 and F3
% stimulation conditions.
%
% Assumed file mapping:
%   0001 -> C3
%   0002 -> F3

%% Select input directory
% Select the root directory that contains:
%   fields/
%   charm/
alldatadir = uigetdir(pwd, 'Select the root folder containing all e-field data');

% Stop the script if the user cancels folder selection.
if isequal(alldatadir, 0)
    error('No folder was selected. Script terminated.');
end

%% Build key paths
fields_path = fullfile(alldatadir, 'fields');
charm_path  = fullfile(alldatadir, 'charm');

% Get subject folders from the charm directory.
dirinfo = dir(charm_path);
dirinfo = dirinfo([dirinfo.isdir]);
dirinfo = dirinfo(~ismember({dirinfo.name}, {'.', '..'}));
subj_names = {dirinfo.name};

%% Initialize result container
% Columns:
%   1  = Subject ID
%   2  = C3 magnE 95th percentile
%   3  = C3 magnE 99th percentile
%   4  = C3 magnE 99.9th percentile
%   5  = F3 magnE 95th percentile
%   6  = F3 magnE 99th percentile
%   7  = F3 magnE 99.9th percentile
magE_result = cell(length(dirinfo), 7);
magE_result(:, 1) = subj_names';

%% Loop over subjects
for subj = 1:length(dirinfo)
    subject_id = subj_names{subj};
    fieldfilepath = fullfile(fields_path, subject_id);

    % Define mesh files for C3 and F3.
    c3_file = fullfile(fieldfilepath, ...
        [subject_id, '_TMS_1-0001_MagVenture_Cool-B65_scalar.msh']);
    f3_file = fullfile(fieldfilepath, ...
        [subject_id, '_TMS_1-0002_MagVenture_Cool-B65_scalar.msh']);

    % Initialize outputs as NaN in case one file is missing.
    c3_95 = NaN; c3_99 = NaN; c3_999 = NaN;
    f3_95 = NaN; f3_99 = NaN; f3_999 = NaN;

    %% Process C3
    if isfile(c3_file)
        surf_c3 = mesh_load_gmsh4(c3_file);
        gm_c3 = mesh_extract_regions(surf_c3, 'elemtype', 'tet', 'region_idx', 2);
        field_idx_c3 = get_field_idx(gm_c3, 'magnE', 'element');
        gm_magnE_c3 = gm_c3.element_data{field_idx_c3}.tetdata;

        c3_95  = prctile(gm_magnE_c3, 95);
        c3_99  = prctile(gm_magnE_c3, 99);
        c3_999 = prctile(gm_magnE_c3, 99.9);
    else
        fprintf('Warning: C3 mesh not found for subject %s\n', subject_id);
    end

    %% Process F3
    if isfile(f3_file)
        surf_f3 = mesh_load_gmsh4(f3_file);
        gm_f3 = mesh_extract_regions(surf_f3, 'elemtype', 'tet', 'region_idx', 2);
        field_idx_f3 = get_field_idx(gm_f3, 'magnE', 'element');
        gm_magnE_f3 = gm_f3.element_data{field_idx_f3}.tetdata;

        f3_95  = prctile(gm_magnE_f3, 95);
        f3_99  = prctile(gm_magnE_f3, 99);
        f3_999 = prctile(gm_magnE_f3, 99.9);
    else
        fprintf('Warning: F3 mesh not found for subject %s\n', subject_id);
    end

    % Store subject results.
    magE_result{subj, 2} = c3_95;
    magE_result{subj, 3} = c3_99;
    magE_result{subj, 4} = c3_999;
    magE_result{subj, 5} = f3_95;
    magE_result{subj, 6} = f3_99;
    magE_result{subj, 7} = f3_999;

    fprintf('Processed subject %s\n', subject_id);
end

%% Convert results to table
column_names = { ...
    'Subj_ID', ...
    'C3_magnE_95', 'C3_magnE_99', 'C3_magnE_999', ...
    'F3_magnE_95', 'F3_magnE_99', 'F3_magnE_999'};

magE_result_table = cell2table(magE_result, 'VariableNames', column_names);

%% Save results
output_file = fullfile(alldatadir, 'magE_percentiles_C3_F3.xlsx');
writetable(magE_result_table, output_file);

disp(['Analysis completed. Results saved to: ', output_file]);
