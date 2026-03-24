clc;
clear;
close all;

% Select the root directory that contains all subject folders.
% Example structure:
% root_dir/
%   ├── 3001/
%   │   └── m2m_3001/
%   │       └── 3001.msh
%   ├── 3006/
%   └── 3007/
root_dir = uigetdir(pwd, 'Select the root CHARM folder');

% Stop the script if the user cancels the folder selection dialog.
if isequal(root_dir, 0)
    error('No folder was selected. Script terminated.');
end

% List all subfolders inside the selected root directory.
d = dir(root_dir);
is_subfolder = [d.isdir];
subfolders = d(is_subfolder);

% Remove "." and ".." from the folder list.
subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'}));

% Preallocate a cell array to store subject ID and tissue volumes.
% Each row will contain:
% {Subject_ID, WM_cm3, GM_cm3, CSF_cm3, ICV_cm3}
results = {};

fprintf('Processing started. Root directory: %s\n', root_dir);

for i = 1:numel(subfolders)
    subject_id = subfolders(i).name;

    % Build the path to the subject-specific m2m folder.
    m2m_folder = fullfile(root_dir, subject_id, ['m2m_' subject_id]);

    % Build the path to the subject-specific mesh file.
    msh_file = fullfile(m2m_folder, [subject_id '.msh']);

    % Skip this subject if the mesh file does not exist.
    if ~isfile(msh_file)
        fprintf('Warning: msh file not found for subject %s. Skipping.\n', subject_id);
        continue;
    end

    % Load the head mesh.
    head_mesh = mesh_load_gmsh4(msh_file);

    % Extract white matter (region_idx = 1), gray matter (2), and CSF (3).
    white_matter = mesh_extract_regions(head_mesh, 'region_idx', 1);
    gray_matter  = mesh_extract_regions(head_mesh, 'region_idx', 2);
    csf          = mesh_extract_regions(head_mesh, 'region_idx', 3);

    % Compute tissue volumes in mm^3.
    wm_volumes  = mesh_get_tetrahedron_sizes(white_matter);
    gm_volumes  = mesh_get_tetrahedron_sizes(gray_matter);
    csf_volumes = mesh_get_tetrahedron_sizes(csf);

    wm_volume  = sum(wm_volumes);
    gm_volume  = sum(gm_volumes);
    csf_volume = sum(csf_volumes);

    % Intracranial volume = WM + GM + CSF.
    intracranial_volume = wm_volume + gm_volume + csf_volume;

    % Convert volumes from mm^3 to cm^3.
    wm_cm3  = wm_volume  / 1000;
    gm_cm3  = gm_volume  / 1000;
    csf_cm3 = csf_volume / 1000;
    icv_cm3 = intracranial_volume / 1000;

    % Print the current subject result.
    fprintf('Subject %s: WM=%.2f, GM=%.2f, CSF=%.2f, ICV=%.2f (cm^3)\n', ...
        subject_id, wm_cm3, gm_cm3, csf_cm3, icv_cm3);

    % Append the current subject result to the results array.
    results(end + 1, :) = {subject_id, wm_cm3, gm_cm3, csf_cm3, icv_cm3};
end

% Convert the results cell array into a table.
T = cell2table(results, ...
    'VariableNames', {'Subject_ID', 'WM_cm3', 'GM_cm3', 'CSF_cm3', 'ICV_cm3'});

% Save the results table as an Excel file in the selected root directory.
output_file = fullfile(root_dir, 'tissue_volumes_summary.xlsx');
writetable(T, output_file);

fprintf('All done! Results saved to %s\n', output_file);
