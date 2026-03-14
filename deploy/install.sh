#!/bin/bash

##############################################################################
# LangBot 一键部署脚本
# 版本：1.0
##############################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

log_error() {
    echo -e "${RED}[ERROR]$(date '+%Y-%m-%d %H:%M:%S')${NC} - $1"
}

# 显示菜单
show_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "    ${BLUE}LangBot 一键部署脚本${NC}"
    echo -e "    ${GREEN}版本: 1.0${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}1.${NC} 包管理器部署 (PyPI + uv)"
    echo -e "${YELLOW}2.${NC} 手动部署"
    echo -e "${YELLOW}3.${NC} Docker 部署 (测试内容)"
    echo -e "${YELLOW}4.${NC} 检查系统环境 (测试内容)"
    echo -e "${RED}0.${NC} 退出"
    echo -e "${CYAN}========================================${NC}"

    read -p "$(echo -e "${CYAN}请选择部署方式 [1-5]: ${NC}")" -r choice

    # 清理输入
    choice=$(echo "$choice" | tr -d '\r' | tr -d '\n' | sed 's/[^0-9]*//g')

    case $choice in
        1)
            log_info "启动包管理器部署..."
            create_directories
            install_uv
            install_langbot
            configure_langbot
            echo ""
            log_success "LangBot 安装完成！"
            log_info "运行 './install.sh start-daemon' 启动服务"
            read -p "按 Enter 继续..."
            show_menu
            ;;
        2)
            log_info "启动手动部署..."
            manual_deploy
            read -p "按 Enter 继续..."
            show_menu
            ;;
        3)
            log_info "启动 Docker 部署 (测试内容)..."
            log_info "========================================"
            log_info "Docker 部署测试内容..."
            log_info "========================================"
            log_info "1. 检查 Docker 环境"
            log_info "2. 克隆 LangBot 仓库"
            log_info "3. 配置 Docker Compose"
            log_info "4. 拉取 Docker 镜像"
            log_info "5. 启动 LangBot 容器"
            log_info "========================================"
            read -p "按 Enter 继续..."
            show_menu
            ;;
        4)
            log_info "检查系统环境 (测试内容)..."
            check_system
            read -p "按 Enter 继续..."
            show_menu
            ;;
        0)
            log_info "退出脚本"
            exit 0
            ;;
        *)
            echo ""
            log_error "输入有误，请重新输入 1-5"
            read -p "按 Enter 继续..."
            show_menu
            ;;
    esac
}

# 检查系统环境
check_system() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "    ${BLUE}系统环境检查${NC}"
    echo -e "${CYAN}========================================${NC}"

    OS=$(uname -s)
    log_info "操作系统: $OS"

    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker 已安装: $DOCKER_VERSION"
    else
        log_warning "Docker 未安装"
    fi

    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        log_success "Python3 已安装: $PYTHON_VERSION"
    else
        log_warning "Python3 未安装"
    fi

    if command -v curl &> /dev/null; then
        log_success "curl 已安装"
    elif command -v wget &> /dev/null; then
        log_success "wget 已安装"
    else
        log_error "curl 或 wget 未安装"
    fi
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."

    if [ ! -d "LangBot" ]; then
        mkdir -p LangBot
    fi

    log_success "目录创建完成"
}

# 安装 uv
install_uv() {
    log_info "安装 uv..."

    if command -v uv &> /dev/null; then
        UV_VERSION=$(uv --version)
        log_success "uv 已安装: $UV_VERSION"
        return 0
    fi

    if command -v pip3 &> /dev/null; then
        pip3 install uv
    elif command -v pip &> /dev/null; then
        pip install uv
    else
        log_error "无法安装 uv，请先安装 pip"
        return 1
    fi

    if [ $? -eq 0 ]; then
        log_success "uv 安装完成"
    else
        log_error "uv 安装失败"
        return 1
    fi
}

# 安装 LangBot
install_langbot() {
    log_info "开始安装 LangBot..."

    if [ ! -d "LangBot" ]; then
        mkdir -p LangBot
    fi

    cd LangBot

    if command -v uvx &> /dev/null; then
        uvx langbot@latest
    else
        log_error "uvx 未安装，请先安装 uv"
        return 1
    fi

    if [ $? -eq 0 ]; then
        log_success "LangBot 安装成功"
        return 0
    else
        log_error "LangBot 安装失败"
        return 1
    fi
}

# 配置 LangBot
configure_langbot() {
    log_info "配置 LangBot..."

    if [ ! -f "LangBot/data/config.yaml" ]; then
        log_warning "配置文件不存在，首次运行将自动生成"
    else
        log_success "配置文件已存在"
    fi
}

# 检查是否为中国网络环境
check_china() {
    # 尝试访问 Google 检测网络环境
    if curl -s --connect-timeout 3 http://www.google.com > /dev/null 2>&1; then
        return 1  # 非中国网络
    else
        return 0  # 中国网络
    fi
}

# 手动部署 - 下载Release包
manual_deploy() {
    log_info "========================================"
    log_info "开始手动部署 LangBot"
    log_info "========================================"
    
    # 保存当前目录
    local CURRENT_DIR=$(pwd)
    
    # 检查依赖
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_error "需要 curl 或 wget 来下载 Release 包"
        return 1
    fi
    
    if ! command -v unzip &> /dev/null; then
        log_warning "unzip 未安装，尝试安装..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq unzip
        elif command -v yum &> /dev/null; then
            sudo yum install -y -q unzip
        else
            log_error "无法自动安装 unzip，请手动安装"
            return 1
        fi
    fi
    
    # 获取最新版本信息
    log_info "正在获取最新版本信息..."
    local LATEST_VERSION
    if command -v curl &> /dev/null; then
        LATEST_VERSION=$(curl -s https://api.github.com/repos/langbot-app/LangBot/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        LATEST_VERSION=$(wget -qO- https://api.github.com/repos/langbot-app/LangBot/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        log_error "获取版本信息失败"
        cd "$CURRENT_DIR"
        return 1
    fi
    log_info "最新版本: $LATEST_VERSION"
    
    # 下载地址（使用 GitHub Release）
    local DOWNLOAD_URL="https://github.com/langbot-app/LangBot/releases/download/${LATEST_VERSION}/langbot-${LATEST_VERSION}-all.zip"
    local download_file="langbot-${LATEST_VERSION}-all.zip"
    
    # 国内镜像优化（使用 gh-proxy）
    check_china
    local IS_CHINA=$?
    if [ $IS_CHINA -eq 0 ]; then
        DOWNLOAD_URL="https://gh-proxy.com/${DOWNLOAD_URL}"
        log_info "使用国内镜像加速: $DOWNLOAD_URL"
    fi
    
    log_info "下载 Release 包: $download_file"
    
    if [ -f "$download_file" ]; then
        log_warning "文件已存在，跳过下载"
    else
        if command -v curl &> /dev/null; then
            curl -L -o "$download_file" "$DOWNLOAD_URL" --progress-bar
        else
            wget -O "$download_file" "$DOWNLOAD_URL" --show-progress
        fi
        
        if [ $? -ne 0 ]; then
            log_error "下载失败，请检查网络连接或手动下载"
            cd "$CURRENT_DIR"
            return 1
        fi
    fi
    
    log_success "下载完成: $download_file"
    
    # 解压Release包
    log_info "解压 Release 包..."
    local extract_dir="LangBot-${LATEST_VERSION}"
    
    if [ -d "$extract_dir" ]; then
        log_warning "目录已存在，删除旧目录..."
        rm -rf "$extract_dir"
    fi
    
    mkdir -p "$extract_dir"
    unzip -q "$download_file" -d "$extract_dir"
    
    if [ $? -ne 0 ]; then
        log_error "解压失败"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    log_success "解压完成: $extract_dir"
    
    # 进入解压目录
    cd "$extract_dir"
    
    # 安装uv
    log_info "安装 uv..."
    if ! command -v uv &> /dev/null; then
        if command -v pip3 &> /dev/null; then
            pip3 install uv
        elif command -v pip &> /dev/null; then
            pip install uv
        else
            log_error "无法安装 uv，请先安装 pip"
            cd "$CURRENT_DIR"
            return 1
        fi
        
        if [ $? -ne 0 ]; then
            log_error "uv 安装失败"
            cd "$CURRENT_DIR"
            return 1
        fi
    else
        log_success "uv 已安装"
    fi
    
    # 使用清华源安装uv（可选）
    log_info "是否使用清华源安装依赖? (y/n)"
    read -r use_tsinghua
    if [[ $use_tsinghua =~ ^[Yy]$ ]]; then
        log_info "使用清华源..."
        pip install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
    fi
    
    # 同步依赖
    log_info "同步依赖..."
    uv sync
    
    if [ $? -ne 0 ]; then
        log_error "依赖同步失败"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    log_success "依赖同步完成"
    
    # 运行主程序生成配置文件
    log_info "运行主程序生成配置文件..."
    log_info "首次运行将自动生成配置文件"
    
    read -p "是否立即运行主程序生成配置文件? (y/n): " -r run_now
    if [[ $run_now =~ ^[Yy]$ ]]; then
        uv run main.py
        
        if [ $? -eq 0 ]; then
            log_success "配置文件生成完成"
        else
            log_warning "程序运行可能遇到问题，请检查输出"
        fi
    else
        log_info "跳过运行主程序"
        log_info "稍后可以使用 'uv run main.py' 启动程序"
    fi
    
    cd "$CURRENT_DIR"
    
    log_success "========================================"
    log_success "手动部署完成！"
    log_success "========================================"
    log_info "部署目录: $(pwd)/$extract_dir"
    log_info "启动命令: cd $extract_dir && uv run main.py"
}

# 显示更新日志
show_changelog() {
    show_menu
}

# 显示帮助
show_help() {
    cat << EOF
========================================================================
    LangBot 一键部署脚本
========================================================================

用法:
  ./install.sh                   # 显示菜单并选择部署方式
  ./install.sh package           # 直接使用包管理器部署
  ./install.sh help              # 显示帮助信息

示例:
  ./install.sh                   # 运行主菜单

========================================================================
EOF
}

# 主函数
main() {
    # case "$1" in
    #     package)
    #         log_info "启动包管理器部署..."
    #         create_directories
    #         install_uv
    #         install_langbot
    #         configure_langbot
    #         echo ""
    #         log_success "LangBot 安装完成！"
    #         log_info "运行 './install.sh start-daemon' 启动服务"
    #         ;;
    #     help|--help|-h|usage|--usage)
    #         show_help
    #         ;;
    #     *)
    #         show_menu
    #         ;;
    # esac
    show_menu
}

# 执行主函数
main "$@"
