#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
import gzip
import tarfile
from pathlib import Path

def run_cmd(cmd, check_error=True, cwd=None):
    """运行命令并处理错误"""
    print(f"[CMD] {cmd}")
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd)
    if check_error and res.returncode != 0:
        print(f"[ERROR] Command failed with return code {res.returncode}")
        print(f"[ERROR] {res.stderr.strip()}")
        return None
    return res

def check_tool_available(tool):
    """检查必要的工具是否可用"""
    if shutil.which(tool) is None:
        print(f"[ERROR] Required tool '{tool}' is not available. Please install it.")
        return False
    return True

def extract_nested_archives(file_path, extract_dir):
    """递归解压嵌套的压缩文件"""
    file_path = Path(file_path)
    extract_dir = Path(extract_dir)
    
    print(f"[INFO] Checking for nested archives in: {file_path}")
    
    # 检查文件类型
    file_cmd = run_cmd(f"file -b '{file_path}'", check_error=False)
    if file_cmd and file_cmd.returncode == 0:
        file_type = file_cmd.stdout.lower()
        print(f"[INFO] File type: {file_type}")
        
        # 处理各种压缩格式
        if any(x in file_type for x in ['.gz', 'gzip']):
            print(f"[INFO] Extracting gzip: {file_path}")
            try:
                with gzip.open(file_path, 'rb') as f_in:
                    # 移除.gz后缀作为输出文件名
                    output_name = file_path.with_suffix('')
                    with open(output_name, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                return output_name
            except Exception as e:
                print(f"[WARN] Failed to extract gzip: {e}")
                
        elif any(x in file_type for x in ['.tar', 'tar archive']):
            print(f"[INFO] Extracting tar: {file_path}")
            try:
                with tarfile.open(file_path, 'r') as tar:
                    tar.extractall(path=extract_dir)
                return extract_dir
            except Exception as e:
                print(f"[WARN] Failed to extract tar: {e}")
                
        elif 'squashfs' in file_type:
            print(f"[INFO] Found squashfs: {file_path}")
            subdir = extract_dir / f"{file_path.stem}_squashfs"
            subdir.mkdir(exist_ok=True)
            
            # 尝试不同的squashfs解压工具
            for tool in ['unsquashfs', 'sasquatch']:
                if check_tool_available(tool):
                    if tool == 'unsquashfs':
                        cmd = f"unsquashfs -f -d '{subdir}' '{file_path}'"
                    else:  # sasquatch
                        cmd = f"sasquatch -d '{subdir}' '{file_path}'"
                    
                    result = run_cmd(cmd, check_error=False)
                    if result and result.returncode == 0:
                        print(f"[INFO] Successfully extracted with {tool}")
                        return subdir
                    else:
                        print(f"[WARN] {tool} failed, trying next method")
            
            print(f"[WARN] Could not extract squashfs file: {file_path}")
            
        elif 'jffs2' in file_type:
            print(f"[INFO] Found jffs2: {file_path}")
            subdir = extract_dir / f"{file_path.stem}_jffs2"
            subdir.mkdir(exist_ok=True)
            
            if check_tool_available('jefferson'):
                cmd = f"jefferson -d '{subdir}' '{file_path}'"
                result = run_cmd(cmd, check_error=False)
                if result and result.returncode == 0:
                    return subdir
            else:
                print(f"[WARN] jefferson not available for jffs2 extraction")
                
        elif 'cpio' in file_type:
            print(f"[INFO] Found cpio: {file_path}")
            subdir = extract_dir / f"{file_path.stem}_cpio"
            subdir.mkdir(exist_ok=True)
            
            cmd = f"cd '{subdir}' && cpio -idm < '{file_path}' 2>/dev/null"
            result = run_cmd(cmd, check_error=False)
            if result and result.returncode == 0:
                return subdir
    
    return None

def recursive_extract(directory, max_depth=5, current_depth=0):
    """递归解压目录中的所有压缩文件"""
    if current_depth >= max_depth:
        return
    
    directory = Path(directory)
    extracted_anything = False
    
    for file_path in directory.rglob("*"):
        if file_path.is_file():
            # 跳过已经解压过的文件
            if any(x in str(file_path) for x in ['_squashfs', '_jffs2', '_cpio', '.extracted']):
                continue
                
            result = extract_nested_archives(file_path, file_path.parent)
            if result:
                extracted_anything = True
                # 递归解压新解压出来的内容
                recursive_extract(result, max_depth, current_depth + 1)
    
    return extracted_anything

def cleanup_output_dir(output_dir):
    """清理输出目录，移除可能冲突的文件"""
    output_dir = Path(output_dir)
    
    # 检查并移除可能冲突的符号链接或文件
    firmware_name = None
    for item in output_dir.iterdir():
        if item.is_symlink() or item.name.endswith('.rar') or item.name.endswith('.bin'):
            print(f"[INFO] Removing conflicting file: {item}")
            if item.is_symlink():
                item.unlink()
            elif item.is_file():
                item.unlink()
            else:
                shutil.rmtree(item)

def unpack_firmware(fw_path: str, output_dir: str):
    fw = Path(fw_path).resolve()
    out = Path(output_dir).resolve()
    
    print(f"[INFO] Unpacking firmware: {fw}")
    print(f"[INFO] Output directory: {out}")
    
    # 创建输出目录
    out.mkdir(parents=True, exist_ok=True)
    
    # 清理输出目录中可能冲突的文件
    cleanup_output_dir(out)

    # 检查binwalk是否可用
    if not check_tool_available('binwalk'):
        sys.exit(1)

    # Step 1: Binwalk extract - 在固件文件所在目录运行以避免路径问题
    print("[INFO] Running binwalk extraction...")
    fw_parent = fw.parent
    fw_name = fw.name
    
    # 使用绝对路径运行binwalk
    binwalk_cmd = f"binwalk -eM '{fw}'"
    result = run_cmd(binwalk_cmd, check_error=False, cwd=str(out))
    
    if result is None or result.returncode != 0:
        print("[WARN] Binwalk extraction had issues, but continuing...")

    # Step 2: Locate extracted directories
    extracted_dirs = list(out.glob("_*")) + list(out.glob("*.extracted"))
    if not extracted_dirs:
        print("[WARN] No extracted directory found by binwalk.")
        # 尝试直接处理固件文件
        extracted_dirs = [out]
    else:
        print(f"[INFO] Found extracted directories: {[str(d) for d in extracted_dirs]}")

    # Step 3: 递归解压嵌套的压缩文件
    print("[INFO] Searching for nested file systems...")
    for root_dir in extracted_dirs:
        print(f"[INFO] Processing directory: {root_dir}")
        if root_dir.exists():
            recursive_extract(root_dir)

    # Step 4: 收集所有可执行文件
    print("[INFO] Collecting executable files...")
    executables = []
    for root_dir in extracted_dirs:
        if not root_dir.exists():
            continue
        for f in root_dir.rglob("*"):
            if f.is_file():
                try:
                    # 检查文件权限和类型
                    if os.access(f, os.X_OK):
                        # 进一步检查是否是ELF二进制文件或脚本
                        file_cmd = run_cmd(f"file -b '{f}'", check_error=False)
                        if file_cmd and file_cmd.returncode == 0:
                            file_type = file_cmd.stdout.lower()
                            if any(x in file_type for x in ['elf', 'executable', 'script', 'shell']):
                                executables.append(f)
                except (PermissionError, OSError) as e:
                    print(f"[WARN] Cannot access {f}: {e}")

    print(f"[INFO] Found {len(executables)} executable files.")

    # 保存可执行文件列表
    list_file = out / "executables.txt"
    try:
        with list_file.open("w") as f:
            for e in executables:
                f.write(str(e) + "\n")
        print(f"[INFO] Executable list saved to {list_file}")
    except Exception as e:
        print(f"[ERROR] Failed to write executable list: {e}")
        # 尝试在当前位置创建文件
        try:
            with open("executables.txt", "w") as f:
                for e in executables:
                    f.write(str(e) + "\n")
            print("[INFO] Executable list saved to ./executables.txt")
        except Exception as e2:
            print(f"[ERROR] Completely failed to save executable list: {e2}")

    print(f"[INFO] Extraction completed in: {out}")
    return list_file

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: unpack_firmware.py <firmware.bin> <output_dir>")
        sys.exit(1)
    unpack_firmware(sys.argv[1], sys.argv[2])