clc;
clear;
close all;

%% Select input directory
% Select the root directory that contains:
%   charm/
%   fields/
alldatadir = uigetdir(pwd, 'Select the root folder containing all e-field data');

% Stop the script if the user cancels folder selection.
if isequal(alldatadir, 0)
    error('No folder was selected. Script terminated.');
end

%% Build key paths
charmpath = fullfile(alldatadir, 'charm');
fieldpath = fullfile(alldatadir, 'fields');

% Get subject folders from the charm directory.
dirinfo = dir(charmpath);
dirinfo = dirinfo([dirinfo.isdir]);
dirinfo = dirinfo(~ismember({dirinfo.name}, {'.', '..'}));
subj_names = {dirinfo.name};

%% Initialize result matrix
subj_distance = nan(length(dirinfo), 2);

%% Loop over subjects
for subj = 1:length(dirinfo)
    subject_id = subj_names{subj};
    filepath = fullfile(fieldpath, subject_id);

    % Find all .log files in the subject directory.
    logFiles = dir(fullfile(filepath, '*.log'));

    % Skip this subject if no log file is found.
    if isempty(logFiles)
        fprintf('Warning: no log file found for subject %s. Skipping.\n', subject_id);
        continue;
    end

    % Read the first available log file.
    distance_file = fullfile(filepath, logFiles(1).name);
    fileContent = fileread(distance_file);

    % Extract coil-cortex distance values using regular expression.
    pattern = 'coil-cortex distance: (\d+\.\d+)mm';
    tokens = regexp(fileContent, pattern, 'tokens');

    % Skip if no valid distance values are found.
    if isempty(tokens)
        fprintf('Warning: no coil-cortex distance found for subject %s. Skipping.\n', subject_id);
        continue;
    end

    % Convert extracted values to numeric and subtract 4 mm.
    temp_values = cellfun(@(x) str2double(x{1}), tokens);
    distances = temp_values - 4;

    % Store the first two distances as C3 and F3.
    if numel(distances) >= 2
        subj_distance(subj, 1) = distances(1);
        subj_distance(subj, 2) = distances(2);
    else
        fprintf('Warning: less than two distance values found for subject %s. Skipping.\n', subject_id);
        continue;
    end
end

%% Create output table
ID = subj_names';
C3_distance = subj_distance(:, 1);
F3_distance = subj_distance(:, 2);
F3_C3_distance_ratio = F3_distance ./ C3_distance;

T = table(ID, C3_distance, F3_distance, F3_C3_distance_ratio);

%% Save results
outputFile = fullfile(alldatadir, 'coil_cortex_distance_summary.xlsx');
writetable(T, outputFile);

disp(['Data has been saved to: ', outputFile]);
