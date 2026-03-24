%% I added the line to extract the 95th percentile of magnE to reply the reviewer's comments
clc;
clear;
close all;

%% Load mesh
alldatadir = uigetdir('Please pick up a folder of ALL e_fields data');
chcpfilepath = [alldatadir, '\fields\'];
temppath = [alldatadir, '\charm\'];
dirinfo = dir(temppath);
dirinfo(1:2) = [];
subj_names = {dirinfo.name};

% Initialize result table
magE_result = cell(length(dirinfo), 4);
magE_result(:, 1) = subj_names; % First column for subject names

for subj = 1:length(dirinfo)
    fieldfilepath = [chcpfilepath, subj_names{subj}];
    field_file = [subj_names{subj}, '_TMS_1-0001_MagVenture_Cool-B65_scalar.msh'];
    msh_file = [fieldfilepath, '\', field_file];
    surf = mesh_load_gmsh4(msh_file);
   
    %% Gray matter extract
    gm = mesh_extract_regions(surf, 'elemtype', 'tet', 'region_idx', 2);
   
    %% Extract magnE
    field_idx = get_field_idx(gm, 'magnE', 'element');
    gm_magnE = gm.element_data{field_idx}.tetdata;
    
    % Calculate different percentiles
    max_magnE_95 = prctile(gm_magnE, 95);  % 95th percentile
    max_magnE_99 = prctile(gm_magnE, 99);
    max_magnE_999 = prctile(gm_magnE, 99.9);
    
    % Store results in the table
    magE_result{subj, 2} = max_magnE_95;
    magE_result{subj, 3} = max_magnE_99;
    magE_result{subj, 4} = max_magnE_999;
end

% Convert cell to table and add column names
column_names = {'Subj_ID', 'magnE_95', 'magnE_99', 'magnE_999'};
magE_result_table = cell2table(magE_result, 'VariableNames', column_names);

% Save results to a file
writetable(magE_result_table, 'magE_percentiles_C3_martin.xls');
disp('Analysis completed. Results saved to magE_percentiles.xls');