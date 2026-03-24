clc;
clear;
close all;

% This script runs GTT for each subject using subject-specific CHARM meshes
% and fiducial coordinates parsed from log files.
%
% Condition mapping:
%   C3 -> first "matsimnibs:" matrix in the log file
%   F3 -> second "matsimnibs:" matrix in the log file

%% Select input and output directories
charm_base = uigetdir(pwd, 'Select the CHARM root folder');
if isequal(charm_base, 0)
    error('No CHARM folder selected. Script terminated.');
end

fields_base = uigetdir(pwd, 'Select the fields/log root folder');
if isequal(fields_base, 0)
    error('No fields folder selected. Script terminated.');
end

output_dir = uigetdir(pwd, 'Select the output folder for GTT results');
if isequal(output_dir, 0)
    error('No output folder selected. Script terminated.');
end

%% Select stimulation condition
choice = menu('Select stimulation condition', 'C3', 'F3');

if choice == 1
    condition_name = 'C3';
    matrix_index = 1;
elseif choice == 2
    condition_name = 'F3';
    matrix_index = 2;
else
    error('No condition selected. Script terminated.');
end

fprintf('Selected condition: %s\n', condition_name);

%% Get subject folders with numeric IDs only
subj_dirs = dir(charm_base);
subj_ids = {};

for i = 1:length(subj_dirs)
    if subj_dirs(i).isdir && ~ismember(subj_dirs(i).name, {'.', '..'})
        dir_name = subj_dirs(i).name;
        if ~isempty(regexp(dir_name, '^\d+$', 'once'))
            subj_ids{end + 1} = dir_name;
        end
    end
end

%% Initialize summary table
all_results = table();
all_results.Properties.Description = ['GTT Results Summary - ' condition_name];

%% Process each subject
for k = 1:length(subj_ids)
    id_str = subj_ids{k};
    fprintf('\n==== Processing subject: %s (%s) ====\n', id_str, condition_name);

    % Build the subject-specific mesh directory path.
    mesh_path = fullfile(charm_base, id_str, ['m2m_' id_str]);

    if ~exist(mesh_path, 'dir')
        warning('Mesh directory not found for subject %s. Skipping.', id_str);
        continue;
    end

    % Extract fiducial coordinates from the subject log files.
    [fiducial, status] = get_fiducial(fields_base, id_str, matrix_index);
    if status == 0
        continue;
    end

    % Configure and run GTT.
    structure = struct();
    structure.Mesh = mesh_path;
    structure.Fiducial = fiducial;
    structure.FiducialType = 'Subject';
    structure.BeginTissue = 'SCALP';
    structure.PlotResults = 0;

    try
        result = GTT(structure);

        % Save the subject-specific result.
        save(fullfile(output_dir, [id_str '_GTT_' condition_name '.mat']), 'result');

        % Add the result to the summary table.
        result_table = [table({id_str}, 'VariableNames', {'ID'}), result];
        all_results = vertcat(all_results, result_table);

        fprintf('[Success] Subject %s processed for %s\n', id_str, condition_name);
    catch ME
        warning('[Error] Processing failed for subject %s (%s): %s', ...
            id_str, condition_name, ME.message);
    end
end

%% Save summary outputs
if ~isempty(all_results)
    save(fullfile(output_dir, ['all_GTT_results_' condition_name '.mat']), 'all_results');
    writetable(all_results, fullfile(output_dir, ['all_GTT_results_' condition_name '.csv']));

    fprintf('\nTotal processed for %s: %d subjects\n', condition_name, height(all_results));
else
    warning('No valid results were generated for %s.', condition_name);
end

%% Local function: get fiducial coordinates
function [fiducial, status] = get_fiducial(base_path, id, matrix_index)
    fiducial = [];
    status = 0;

    log_dir = fullfile(base_path, id);
    if ~exist(log_dir, 'dir')
        warning('Log directory not found for %s', id);
        return;
    end

    log_files = dir(fullfile(log_dir, '*.log'));
    if isempty(log_files)
        warning('No log files found for %s', id);
        return;
    end

    % Search all available log files for a valid fiducial matrix.
    for f = 1:length(log_files)
        log_path = fullfile(log_dir, log_files(f).name);
        [fiducial, found] = parse_log(log_path, matrix_index);
        if found
            status = 1;
            return;
        end
    end

    warning('No valid matrix found for %s', id);
end

%% Local function: parse log file
function [fiducial, found] = parse_log(log_path, matrix_index)
    fiducial = [];
    found = false;

    fid = fopen(log_path, 'rt');
    if fid == -1
        return;
    end

    % Read the file line by line.
    file_content = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    lines = file_content{1};

    % Find all "matsimnibs:" markers and select the requested one.
    matrix_starts = find(contains(lines, 'matsimnibs:'));
    if length(matrix_starts) < matrix_index || (matrix_starts(matrix_index) + 3) > numel(lines)
        return;
    end

    % Extract the selected 4x4 matrix.
    try
        matrix = zeros(4, 4);
        for i = 1:4
            line = lines{matrix_starts(matrix_index) + i};
            line = regexprep(line, {'\[', '\]'}, '');
            nums = sscanf(line, '%f');
            matrix(i, :) = nums(1:4)';
        end

        % Use the translation component as the fiducial coordinate.
        fiducial = matrix(1:3, 4)';
        found = true;
    catch
        warning('Matrix parsing failed in %s', log_path);
    end
end
