clc;
clear;
close all;

%% load folder
alldatadir = uigetdir('Please pick up a folder of ALL e_fields data');

chcpfilepath = [alldatadir, '\fields\hcp\'];
temppath     = [alldatadir, '\charm\hcp\'];

dirinfo = dir(temppath);
dirinfo(1:2) = [];
subj_names = {dirinfo.name};

%% ROI radius
r = 10;

%% MNI coordinates
mni_M1 = [-52.2, -16.4, 57.8];
mni_F3 = [-35.5, 49.4, 32.4];

%% preallocate
avg_field_roi_results = nan(length(dirinfo), 2);

%% loop subjects
for subj = 1:length(dirinfo)

    m2mfilepath = [alldatadir, '\charm\hcp\', subj_names{subj}];
    m2m_file    = ['m2m_', subj_names{subj}];

    fieldfilepath = [chcpfilepath, subj_names{subj}, '\simulation_outputs\subject_overlays'];

    %% ---------------- M1: use 0001 file ----------------
    field_file_M1 = [subj_names{subj}, '_TMS_1-0001_MagVenture_Cool-B65_scalar_central.msh'];
    msh_file_M1   = [fieldfilepath, '\', field_file_M1];

    surf_M1 = mesh_load_gmsh4(msh_file_M1);

    field_idx_M1 = get_field_idx(surf_M1, 'E_magn', 'node');
    field_Emagn_M1 = surf_M1.node_data{field_idx_M1}.data;

    nodes_areas_M1 = mesh_get_node_areas(surf_M1);

    sub_coords_M1 = mni2subject_coords(mni_M1, fullfile(m2mfilepath, m2m_file));
    roi_M1 = sqrt(sum(bsxfun(@minus, surf_M1.nodes, sub_coords_M1).^2, 2)) < r;

    avg_field_roi_M1 = sum(field_Emagn_M1(roi_M1) .* nodes_areas_M1(roi_M1)) / sum(nodes_areas_M1(roi_M1));

    %% ---------------- F3: use 0002 file ----------------
    field_file_F3 = [subj_names{subj}, '_TMS_1-0002_MagVenture_Cool-B65_scalar_central.msh'];
    msh_file_F3   = [fieldfilepath, '\', field_file_F3];

    surf_F3 = mesh_load_gmsh4(msh_file_F3);

    field_idx_F3 = get_field_idx(surf_F3, 'E_magn', 'node');
    field_Emagn_F3 = surf_F3.node_data{field_idx_F3}.data;

    nodes_areas_F3 = mesh_get_node_areas(surf_F3);

    sub_coords_F3 = mni2subject_coords(mni_F3, fullfile(m2mfilepath, m2m_file));
    roi_F3 = sqrt(sum(bsxfun(@minus, surf_F3.nodes, sub_coords_F3).^2, 2)) < r;

    avg_field_roi_F3 = sum(field_Emagn_F3(roi_F3) .* nodes_areas_F3(roi_F3)) / sum(nodes_areas_F3(roi_F3));

    %% save subject results
    avg_field_roi_results(subj,1) = avg_field_roi_M1;
    avg_field_roi_results(subj,2) = avg_field_roi_F3;

end

%% save mat
save('avg_roi_10_M1_F3_Emagn.mat', 'avg_field_roi_results', 'subj_names');

%% write excel
fname = 'avg_roi_10_M1_F3_Emagn.xlsx';

subj_ID = cell(length(dirinfo),1);
for i = 1:length(dirinfo)
    subj_ID{i,1} = subj_names{i};
end

result_label = {'Subj_ID', 'E_magn_M1_10', 'E_magn_F3_10'};

writecell(result_label, fname, 'Sheet', 'avg_10_M1_F3', 'Range', 'A1');
writecell(subj_ID,      fname, 'Sheet', 'avg_10_M1_F3', 'Range', 'A2');
writematrix(avg_field_roi_results, fname, 'Sheet', 'avg_10_M1_F3', 'Range', 'B2');
