clc;
clear all;
close all;

% 顶层目录（包含 3001, 3006, 3007... 这些 subject 文件夹）
root_dir = 'E:\all_data\martin_data\charm';

% 列出 root_dir 下面所有子文件夹
d = dir(root_dir);
is_subfolder = [d.isdir];                 % 只要文件夹
subfolders = d(is_subfolder);

% 去掉 '.' 和 '..'
subfolders = subfolders(~ismember({subfolders.name}, {'.','..'}));

% 预分配一个结果 cell，用来存 subject ID 和体积
results = {};  % 每行：{subject_ID, WM, GM, CSF, ICV}

for i = 1:numel(subfolders)
    subject_id = subfolders(i).name;  % 比如 '3001'
    
    % 构造 m2m_subjectID 文件夹路径，例如 ...\3001\m2m_3001
    m2m_folder = fullfile(root_dir, subject_id, ['m2m_' subject_id]);
    
    % 构造 .msh 文件路径，例如 ...\3001\m2m_3001\3001.msh
    msh_file = fullfile(m2m_folder, [subject_id '.msh']);
    
    % 检查文件是否存在
    if ~isfile(msh_file)
        fprintf('Warning: msh file not found for subject %s, skip.\n', subject_id);
        continue;
    end
    
    % 读取网格
    head_mesh = mesh_load_gmsh4(msh_file);
    
    % 提取白质 (region_idx 1), 灰质 (2), CSF (3)
    white_matter = mesh_extract_regions(head_mesh, 'region_idx', 1);
    gray_matter  = mesh_extract_regions(head_mesh, 'region_idx', 2);
    csf          = mesh_extract_regions(head_mesh, 'region_idx', 3);
    
    % 计算各组织体积 (单位: mm³)
    wm_volumes  = mesh_get_tetrahedron_sizes(white_matter);
    gm_volumes  = mesh_get_tetrahedron_sizes(gray_matter);
    csf_volumes = mesh_get_tetrahedron_sizes(csf);
    
    wm_volume  = sum(wm_volumes);
    gm_volume  = sum(gm_volumes);
    csf_volume = sum(csf_volumes);
    
    % 颅内容积 (WM + GM + CSF)
    intracranial_volume = wm_volume + gm_volume + csf_volume;
    
    % 转成 cm³ 保存
    wm_cm3  = wm_volume  / 1000;
    gm_cm3  = gm_volume  / 1000;
    csf_cm3 = csf_volume / 1000;
    icv_cm3 = intracranial_volume / 1000;
    
    % 打印一下当前 subject 的结果
    fprintf('Subject %s: WM=%.2f, GM=%.2f, CSF=%.2f, ICV=%.2f (cm^3)\n', ...
        subject_id, wm_cm3, gm_cm3, csf_cm3, icv_cm3);
    
    % 追加到 results（subject_id 作为字符/字符串都可以）
    results(end+1, :) = {subject_id, wm_cm3, gm_cm3, csf_cm3, icv_cm3};
end

% 把结果转为表，设置列名
T = cell2table(results, ...
    'VariableNames', {'Subject_ID', 'WM_cm3', 'GM_cm3', 'CSF_cm3', 'ICV_cm3'});

% 写入 Excel
output_file = fullfile(root_dir, 'martin_tissue_volumes.xlsx');
writetable(T, output_file);  % 默认写到第一个 Sheet，从 A1 开始 [web:46][web:49]

fprintf('All done! Results saved to %s\n', output_file);
