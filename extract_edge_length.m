% 设定基础路径
baseDir = 'E:/all_data/open_data/hcp/charm';%% change to "chcp" if want to extract chcp data

baseDir= 'E:/all_data/own_data/penny_Tim_data/charm'

% 获取基础路径下的所有受试者文件夹
folders = dir(baseDir);
% 过滤掉非文件夹以及 '.' 和 '..'
folders = folders([folders.isdir]);
folders(ismember({folders.name}, {'.', '..'})) = [];

% 初始化一个空的 Table 来存储结果
results = table();

fprintf('开始处理，主目录: %s\n', baseDir);

% 遍历每一个受试者文件夹
for i = 1:length(folders)
    subjID = folders(i).name;
    
    % 构造对应受试者的 HTML 日志文件路径
    % 示例: E:/all_data/open_data/chcp/charm/3014/m2m_3014/charm_log.html
    logFilePath = fullfile(baseDir, subjID, ['m2m_', subjID], 'charm_log.html');
    
    % 检查文件是否存在
    if ~isfile(logFilePath)
        fprintf('未找到文件，跳过受试者: %s\n', subjID);
        continue;
    end
    
    % 逐行读取文件内容 (需要 MATLAB R2020a 或更高版本)
    lines = readlines(logFilePath);
    
    % 初始化我们要提取的变量为 NaN (防止没找到时报错)
    avgLen = NaN;
    minLen = NaN;
    maxLen = NaN;
    percentage = NaN;
    
    % 从文件的【最底端】开始倒序查找
    for j = length(lines):-1:1
        % 寻找标识符: DEBUG:   -- RESULTING EDGE LENGTHS
        if contains(lines(j), "DEBUG:   -- RESULTING EDGE LENGTHS")
            
            % 找到标识符后，从当前行往下看几行（覆盖我们需要的数据行）
            % 为防止越界，取 j 和 j+10 的最小值
            for k = j : min(j+10, length(lines))
                strLine = lines(k);
                
                % 1. 提取 AVERAGE LENGTH
                if contains(strLine, "AVERAGE LENGTH")
                    % 正则匹配：AVERAGE LENGTH 后面跟着多个空格和数字/小数点
                    tok = regexp(strLine, 'AVERAGE LENGTH\s+([\d\.]+)', 'tokens');
                    if ~isempty(tok), avgLen = str2double(tok{1}{1}); end
                    
                % 2. 提取 SMALLEST EDGE LENGTH
                elseif contains(strLine, "SMALLEST EDGE LENGTH")
                    tok = regexp(strLine, 'SMALLEST EDGE LENGTH\s+([\d\.]+)', 'tokens');
                    if ~isempty(tok), minLen = str2double(tok{1}{1}); end
                    
                % 3. 提取 LARGEST EDGE LENGTH
                elseif contains(strLine, "LARGEST") && contains(strLine, "EDGE LENGTH")
                    % 使用 \s+ 兼容 "LARGEST  EDGE" 中间有多个空格的情况
                    tok = regexp(strLine, 'LARGEST\s+EDGE LENGTH\s+([\d\.]+)', 'tokens');
                    if ~isempty(tok), maxLen = str2double(tok{1}{1}); end
                    
                % 4. 提取 0.71 < L < 1.41 中的百分比
                elseif contains(strLine, "0.71 < L < 1.41")
                    % 正则解释：匹配 0.71 < L < 1.41 -> 任意空白 -> 任意数字(总数) -> 任意空白 -> (需要提取的小数) -> 任意空白 -> %
                    tok = regexp(strLine, '0\.71 < L < 1\.41\s+\d+\s+([\d\.]+)\s*%', 'tokens');
                    if ~isempty(tok), percentage = str2double(tok{1}{1}); end
                end
            end
            
            % 既然已经找到了文件最底部（最后一次）的结果，提取完即可跳出倒序循环
            break;
        end
    end
    
    % 将提取出的结果整理成新的一行，加入结果表格中
    newRow = table(string(subjID), avgLen, minLen, maxLen, percentage, ...
        'VariableNames', {'SubjectID', 'AverageLength', 'SmallestEdgeLength', 'LargestEdgeLength', 'Percentage_071_141'});
    results = [results; newRow];
    
    fprintf('成功提取受试者: %s\n', subjID);
end

% 导出为 CSV 文件到主目录下，方便查看
outputFile = fullfile(baseDir, 'penny_Tim_mesh_results_summary.csv');
writetable(results, outputFile);
fprintf('\n处理完毕！汇总结果已保存至: %s\n', outputFile);