clc; clear all; close all;
% 定义基础路径
charm_base = 'E:\all_data\charm\hcp';
fields_base = 'E:\all_data\fields\hcp';
output_dir = 'E:\all_data\hcp_GTT_results_F3'; % 结果保存路径

% 创建结果目录（如果不存在）
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% 获取所有数字ID的文件夹
subj_dirs = dir(charm_base);
subj_ids = {};
for i = 1:length(subj_dirs)
    if subj_dirs(i).isdir && ~ismember(subj_dirs(i).name, {'.', '..'})
        dir_name = subj_dirs(i).name;
        if ~isempty(regexp(dir_name, '^\d+$', 'once'))
            subj_ids{end+1} = dir_name;
        end
    end
end

% 初始化总结果表格
all_results = table();
all_results.Properties.Description = 'GTT Results Summary';

% 循环处理每个受试者
for k = 1:length(subj_ids)
    id_str = subj_ids{k};
    fprintf('\n==== Processing subject: %s ====\n', id_str);
    
    % ========== 1. 构建mesh路径 ==========
    mesh_path = fullfile(charm_base, id_str, ['m2m_' id_str]);
    if ~exist(mesh_path, 'dir')
        warning('Mesh directory not found. Skipping...');
        continue;
    end
    
    % ========== 2. 提取Fiducial坐标 ==========
    [fiducial, status] = get_fiducial(fields_base, id_str);
    if status == 0
        continue; % 错误已在子函数中提示
    end
    
    % ========== 3. 配置并执行GTT ==========
    structure = struct();
    structure.Mesh = mesh_path;
    structure.Fiducial = fiducial;
    structure.FiducialType = 'Subject';
    structure.BeginTissue = 'SCALP';
    structure.PlotResults = 0;
    
    try
        % 执行GTT并捕获结果
        result = GTT(structure); 
        
        % ========== 4. 保存结果 ==========
        % (A) 保存为单独文件
        save(fullfile(output_dir, [id_str '_GTT.mat']), 'result');
        
        % (B) 添加到总表
        result_table = [table({id_str}, 'VariableNames', {'ID'}), result];
        all_results = vertcat(all_results, result_table);
        
        fprintf('[Success] Subject %s processed\n', id_str);
    catch ME
        warning('[Error] Processing failed: %s', ME.message);
    end
end

% ========== 5. 保存总结果 ==========
if ~isempty(all_results)
    % 保存为MAT文件
    save(fullfile(output_dir, 'all_results.mat'), 'all_results');
    
    % 另存为CSV文件
    writetable(all_results, fullfile(output_dir, 'all_results.csv'));
    
    fprintf('\nTotal processed: %d subjects\n', height(all_results));
else
    warning('No valid results were generated');
end

% ========== 子函数：获取Fiducial坐标 ==========
function [fiducial, status] = get_fiducial(base_path, id)
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
    
    % 遍历所有日志文件
    for f = 1:length(log_files)
        log_path = fullfile(log_dir, log_files(f).name);
        [fiducial, found] = parse_log(log_path);
        if found
            status = 1;
            return;
        end
    end
    
    warning('No valid matrix found for %s', id);
end

% ========== 子函数：解析日志文件 C3==========
% function [fiducial, found] = parse_log(log_path)
%     fiducial = [];
%     found = false;
%     
%     fid = fopen(log_path, 'rt');
%     if fid == -1, return; end
%     
%     % 使用文本扫描精确匹配
%     file_content = textscan(fid, '%s', 'Delimiter', '\n');
%     fclose(fid);
%     lines = file_content{1};
%     
%     % 寻找矩阵起始行
%     matrix_start = find(contains(lines, 'matsimnibs:'), 1);
%     if isempty(matrix_start) || (matrix_start+3) > numel(lines)
%         return;
%     end
%     
%     % 提取4x4矩阵
%     try
%         matrix = zeros(4,4);
%         for i = 1:4
%             line = lines{matrix_start + i};
%             line = regexprep(line, {'\[', '\]'}, '');
%             nums = sscanf(line, '%f');
%             matrix(i,:) = nums(1:4)';
%         end
%         fiducial = matrix(1:3,4)'; % 转为行向量
%         found = true;
%     catch
%         warning('Matrix parsing failed in %s', log_path);
%     end
% end

% ========== 子函数：解析日志文件 F3==========
function [fiducial, found] = parse_log(log_path)
    fiducial = [];
    found = false;
    
    fid = fopen(log_path, 'rt');
    if fid == -1, return; end
    
    % 使用文本扫描精确匹配
    file_content = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    lines = file_content{1};
    
    % 寻找第二个矩阵起始行
    matrix_starts = find(contains(lines, 'matsimnibs:'));
    if length(matrix_starts) < 2 || (matrix_starts(2)+3) > numel(lines)
        return;
    end
    
    % 提取第二个4x4矩阵
    try
        matrix = zeros(4,4);
        for i = 1:4
            line = lines{matrix_starts(2) + i};
            line = regexprep(line, {'\[', '\]'}, '');
            nums = sscanf(line, '%f');
            matrix(i,:) = nums(1:4)';
        end
        fiducial = matrix(1:3,4)'; % 转为行向量
        found = true;
    catch
        warning('Matrix parsing failed in %s', log_path);
    end
end