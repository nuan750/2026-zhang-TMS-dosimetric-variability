clc;
clear;
close all;

% Select the root CHARM directory that contains all subject folders.
% Example:
% /path/to/charm/
%   ├── subject_01/
%   │   └── m2m_subject_01/charm_log.html
%   └── subject_02/
baseDir = uigetdir(pwd, 'Select the CHARM root folder');

% Stop the script if the user cancels the folder selection dialog.
if isequal(baseDir, 0)
    error('No folder was selected. Script terminated.');
end

% Get all subject folders under the selected directory.
folders = dir(baseDir);
folders = folders([folders.isdir]);
folders(ismember({folders.name}, {'.', '..'})) = [];

% Initialize an empty table to store extracted results.
results = table();

fprintf('Processing started. Root directory: %s\n', baseDir);

% Loop through each subject folder.
for i = 1:length(folders)
    subjID = folders(i).name;

    % Build the expected path to the subject-specific HTML log file.
    logFilePath = fullfile(baseDir, subjID, ['m2m_', subjID], 'charm_log.html');

    % Skip this subject if the HTML log file does not exist.
    if ~isfile(logFilePath)
        fprintf('Log file not found. Skipping subject: %s\n', subjID);
        continue;
    end

    % Read the log file line by line.
    % This requires MATLAB R2020a or later.
    lines = readlines(logFilePath);

    % Initialize output variables as NaN in case the target values are not found.
    avgLen = NaN;
    minLen = NaN;
    maxLen = NaN;
    percentage = NaN;

    % Search from the bottom of the file to find the last reported result block.
    for j = length(lines):-1:1
        if contains(lines(j), "DEBUG:   -- RESULTING EDGE LENGTHS")

            % After locating the marker line, inspect the following lines.
            for k = j:min(j + 10, length(lines))
                strLine = lines(k);

                % Extract AVERAGE LENGTH
                if contains(strLine, "AVERAGE LENGTH")
                    tok = regexp(strLine, 'AVERAGE LENGTH\s+([\d\.]+)', 'tokens');
                    if ~isempty(tok)
                        avgLen = str2double(tok{1}{1});
                    end

                % Extract SMALLEST EDGE LENGTH
                elseif contains(strLine, "SMALLEST EDGE LENGTH")
                    tok = regexp(strLine, 'SMALLEST EDGE LENGTH\s+([\d\.]+)', 'tokens');
                    if ~isempty(tok)
                        minLen = str2double(tok{1}{1});
                    end

                % Extract LARGEST EDGE LENGTH
                elseif contains(strLine, "LARGEST") && contains(strLine, "EDGE LENGTH")
                    tok = regexp(strLine, 'LARGEST\s+EDGE LENGTH\s+([\d\.]+)', 'tokens');
                    if ~isempty(tok)
                        maxLen = str2double(tok{1}{1});
                    end

                % Extract the percentage for 0.71 < L < 1.41
                elseif contains(strLine, "0.71 < L < 1.41")
                    tok = regexp(strLine, '0\.71 < L < 1\.41\s+\d+\s+([\d\.]+)\s*%', 'tokens');
                    if ~isempty(tok)
                        percentage = str2double(tok{1}{1});
                    end
                end
            end

            % Stop after extracting the last matching result block.
            break;
        end
    end

    % Store the extracted values in one table row.
    newRow = table(string(subjID), avgLen, minLen, maxLen, percentage, ...
        'VariableNames', {'SubjectID', 'AverageLength', 'SmallestEdgeLength', 'LargestEdgeLength', 'Percentage_071_141'});

    results = [results; newRow];

    fprintf('Successfully processed subject: %s\n', subjID);
end

% Save the summary CSV file in the selected root directory.
outputFile = fullfile(baseDir, 'mesh_results_summary.csv');
writetable(results, outputFile);

fprintf('\nProcessing completed. Summary saved to: %s\n', outputFile);
