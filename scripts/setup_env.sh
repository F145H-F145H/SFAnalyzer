#!/usr/bin/env bash

# ======================================================
# SFAnalyzer Environment Setup Script (Ubuntu 24.04)
# Author: F145H
# ======================================================
#!/bin/bash

# SFAnalyzer 环境安装脚本
# 使用方式: source scripts/setup_env.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"
VENV_DIR="$PROJECT_ROOT/.venv"

echo "=============================================="
echo "    SFAnalyzer 环境安装脚本"
echo "=============================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查当前目录是否为 SFAnalyzer
check_project_directory() {
    local current_dir=$(basename "$PROJECT_ROOT")
    local expected_dir="SFAnalyzer"
    
    if [ "$current_dir" != "$expected_dir" ]; then
        log_error "当前目录 '$current_dir' 不是 '$expected_dir'"
        log_error "请确保在正确的项目目录中运行此脚本"
        return 1
    fi
    
    log_info "项目目录检查通过: $current_dir"
    return 0
}

# 创建虚拟环境
create_venv() {
    log_info "创建 Python 虚拟环境..."
    cd "$PROJECT_ROOT"

    if [ ! -d "$VENV_DIR" ]; then
        python3 -m venv "$VENV_DIR"
        log_info "虚拟环境创建在: $VENV_DIR"
    else
        log_warn "虚拟环境已存在，跳过创建"
    fi
    
    # 激活虚拟环境
    log_info "激活虚拟环境..."
    source "$VENV_DIR/bin/activate"
}

# 安装Python依赖
install_python_deps() {
    log_info "安装Python依赖..."
    
    if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        pip install -r "$PROJECT_ROOT/requirements.txt"
    else
        log_warn "requirements.txt 未找到，跳过..."
    fi
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖包..."
    sudo apt update
    sudo apt install -y \
        python3 python3-pip python3-venv \
        git wget curl unzip axel \
        build-essential cmake git \
        default-jdk file binutils
}

# 安装 Ghidra
install_ghidra() {
    log_info "安装 Ghidra..."
    
    local GHIDRA_VERSION="11.4.2"
    local GHIDRA_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.4.2_build/ghidra_11.4.2_PUBLIC_20250826.zip"
    local GHIDRA_DIR="$TOOLS_DIR/ghidra"
    
    if [ -d "$GHIDRA_DIR" ]; then
        log_warn "Ghidra 已安装，跳过"
        return 0
    fi
    
    mkdir -p "$TOOLS_DIR"
    cd "$TOOLS_DIR"
    
    log_info "下载 Ghidra..."
    axel -n 4 -o ghidra.zip "$GHIDRA_URL"
    
    log_info "解压 Ghidra..."
    unzip -q ghidra.zip -d "$TOOLS_DIR"
    rm ghidra.zip
    
    # 重命名目录以移除版本号
    mv ghidra_* ghidra
    
    log_info "Ghidra 安装完成: $GHIDRA_DIR"
    
    # 添加到环境变量
    export PATH="$GHIDRA_DIR:$PATH"
    echo "export PATH=\"$GHIDRA_DIR:\$PATH\"" >> "$VENV_DIR/bin/activate"
}

# 安装 Rust 编译器
install_rust() {
    log_info "安装 Rust 编译器..."
    
    if command -v cargo &> /dev/null; then
        log_warn "Rust 已安装，跳过"
        return 0
    fi
    
    # 安装 Rust
    log_info "下载并安装 Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # 加载 Rust 环境变量
    source "$HOME/.cargo/env"
    
    # 将 Rust 环境变量添加到虚拟环境的激活脚本中
    echo 'source "$HOME/.cargo/env"' >> "$VENV_DIR/bin/activate"
    
    log_info "Rust 安装完成"
}


# 安装和编译 Binwalk
install_binwalk() {
    log_info "安装 Binwalk..."
    
    local BINWALK_DIR="$TOOLS_DIR/binwalk"
    
    if command -v binwalk &> /dev/null; then
        log_warn "Binwalk 已安装，跳过"
        return 0
    fi
    
    mkdir -p "$TOOLS_DIR"
    cd "$TOOLS_DIR"
    
    log_info "克隆 Binwalk 源码..."
    git clone https://github.com/ReFirmLabs/binwalk.git "$BINWALK_DIR"
    cd "$BINWALK_DIR"
    
    log_info "编译和安装 Binwalk..."
    sudo ./dependencies/ubuntu.sh

    cargo build --release

    log_info "Binwalk 安装完成"
}

# 设置环境变量
setup_environment() {
    log_info "设置环境变量..."
    
    # 创建环境变量设置文件
    cat > "$PROJECT_ROOT/.sfa_env" << EOF
# SFAnalyzer 环境变量
export SFA_PROJECT_ROOT="$PROJECT_ROOT"
export SFA_VENV_DIR="$VENV_DIR"
export SFA_TOOLS_DIR="$TOOLS_DIR"
export PATH="\$SFA_TOOLS_DIR/ghidra:\$PATH"

# 激活虚拟环境
source "\$SFA_VENV_DIR/bin/activate"
EOF

    log_info "环境变量文件创建在: $PROJECT_ROOT/.sfa_env"
    
    # 提示用户
    echo ""
    log_info "安装完成！"
    echo ""
    log_info "要使用此环境，请运行:"
    echo "  source $PROJECT_ROOT/.sfa_env"
    echo ""
    log_info "或者手动激活虚拟环境:"
    echo "  source $VENV_DIR/bin/activate"
    echo ""
    log_info "项目结构:"
    echo "  项目根目录: $PROJECT_ROOT"
    echo "  虚拟环境: $VENV_DIR"
    echo "  工具目录: $TOOLS_DIR"
    echo "  Python代码: $PROJECT_ROOT/src/python"
}

# 主安装函数
main() {
    log_info "开始安装 SFAnalyzer 环境..."
    log_info "项目根目录: $PROJECT_ROOT"
    
    check_project_directory

    # 创建必要的目录
    mkdir -p "$TOOLS_DIR"
    mkdir -p "$PROJECT_ROOT/data"
    mkdir -p "$PROJECT_ROOT/results"
    
    # 执行安装步骤
    create_venv
    install_system_deps
    install_python_deps
    install_ghidra
    install_rust
    install_binwalk
    setup_environment
    
    log_info "所有安装步骤完成！"
}

# 如果脚本被直接执行，运行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "请使用 'source' 命令执行此脚本:"
    log_error "  source $0"
    exit 1
else
    # 当使用 source 执行时，运行主函数
    main "$@"
fi