clc;
clear;
close all

%% load mesh
alldatadir = uigetdir('Please pick up a folder of ALL e_fields data');
charmpath = [alldatadir, '\charm\'];
fieldpath = [alldatadir, '\fields\'];
dirinfo = dir(charmpath);
dirinfo(1:2) = [];
subj_names = {dirinfo.name};
subj_distance = [];

for subj = 1:length(dirinfo)
    filepath = [fieldpath, subj_names{subj}];
    % Find all .log files in the directory
    logFiles = dir(fullfile(filepath, '*.log'));
    distance_file = fullfile(filepath, logFiles(1).name);
    % Read the file content
    fileContent = fileread(distance_file);

    % Regular expression to extract coil-cortex distances
    pattern = 'coil-cortex distance: (\d+\.\d+)mm';
    tokens = regexp(fileContent, pattern, 'tokens');

    % Convert extracted tokens to numbers
    Temp = cellfun(@(x) str2double(x{1}), tokens);
    distances = Temp - 4;
    subj_distance(subj, :) = distances;
end

% Create a table with the required data
ID = subj_names';
C3_distance = subj_distance(:, 1);
F3_distance = subj_distance(:, 2);
F3_C3_distance_ratio = F3_distance ./ C3_distance;

% Create a table
T = table(ID, C3_distance, F3_distance, F3_C3_distance_ratio);

% Write the table to an Excel file
outputFile = fullfile(alldatadir, 'distance.xlsx');
writetable(T, outputFile);

disp('Data has been saved to output.xlsx');
