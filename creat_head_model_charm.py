import os
import subprocess

# 设置基础目录
base_dir = Path("path/to/your/charm_folder")

# 遍历 charm 目录下的所有 ID 文件夹
for id_folder in os.listdir(base_dir):
    id_path = os.path.join(base_dir, id_folder)

    # 检查是否为目录
    if os.path.isdir(id_path):
        # 构建 org 子文件夹的路径
        org_path = os.path.join(id_path, "org")

        # 检查 org 子文件夹是否存在
        if os.path.isdir(org_path):
            # 构建两个输入文件路径
            t1_file = os.path.join(org_path, f"{id_folder}_T1w.nii.gz")
            t2_file = os.path.join(org_path, f"{id_folder}_T2w.nii.gz")

            # 检查两个输入文件是否都存在
            if os.path.exists(t1_file) and os.path.exists(t2_file):
                # 构建命令，注意命令中的文件路径使用相对路径 org/...
                command = f"charm {id_folder} org/{id_folder}_T1w.nii.gz org/{id_folder}_T2w.nii.gz --forceqform"

                # 打印正在处理的ID
                print(f"Processing ID: {id_folder}")

                # 切换到ID文件夹
                os.chdir(id_path)
                try:
                    # 执行命令
                    subprocess.run(command, shell=True, check=True)
                    print(f"Successfully processed ID: {id_folder}")
                except subprocess.CalledProcessError as e:
                    print(f"Error processing ID {id_folder}: {e}")
                # 切换回基础目录
                os.chdir(base_dir)
            else:
                print(f"Input files not found for ID: {id_folder}")
        else:
            print(f"Org folder not found for ID: {id_folder}")
    else:
        print(f"Skipping non-directory: {id_folder}")