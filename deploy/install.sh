#!/bin/bash

##############################################################################
# LangBot 一键部署脚本
# 功能：支持包管理器、手动部署、Docker 三种部署方式
# 作者：LangBot 部署脚本
# 版本：1.0
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查 sudo 权限
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log_warning "此脚本可能需要 sudo 权限"
        read -p "是否继续？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 显示更新日志
show_changelog() {
    show_menu
}

# 显示菜单
show_menu() {
    clear
    echo "========================================"
    echo "    LangBot 一键部署脚本"
    echo "    版本: 1.0.0"
    echo "========================================"
    echo "1. 包管理器部署 (PyPI + uv)"
    echo "2. 手动部署 (源码编译)"
    echo "3. Docker 部署 (推荐)"
    echo "4. 检查系统环境"
    echo "5. 退出"
    echo "========================================"
    read -p "请选择部署方式 [1-5]: " -r choice
    # 清理输入，移除可能的多余字符
    choice=$(echo "$choice" | tr -d '\r' | tr -d '\n' | sed 's/[^0-9]*//g')
    echo "DEBUG: choice='$choice'"
    case $choice in
        1)
            log_info "启动包管理器部署..."
            "$(dirname "$0")/install-package.sh" install
            show_menu
            ;;
        2)
            log_info "启动手动部署..."
            "$(dirname "$0")/install-manual.sh" install
            show_menu
            ;;
        3)
            log_info "启动 Docker 部署..."
            "$(dirname "$0")/install-docker.sh" install
            show_menu
            ;;
        4)
            log_info "检查系统环境..."
            check_system
            show_menu
            ;;
        5)
            log_info "退出脚本"
            exit 0
            ;;
        *)
            log_error "无效的选择，请输入 1-5"
            show_menu
            ;;
    esac
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
  ./install.sh manual            # 直接使用手动部署
  ./install.sh docker            # 直接使用 Docker 部署
  ./install.sh check             # 检查系统环境
  ./install.sh help              # 显示帮助信息

示例:
  ./install.sh                   # 运行主菜单
  ./install.sh docker            # 直接启动 Docker 部署

========================================================================
EOF
}

# 检查系统环境
check_system() {
    clear
    echo "========================================"
    echo "    系统环境检查"
    echo "========================================"

    # 检查操作系统
    OS=$(uname -s)
    log_info "操作系统: $OS"

    # 检查 Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker 已安装: $DOCKER_VERSION"
        DOCKER_AVAILABLE=1
    else
        log_warning "Docker 未安装"
        DOCKER_AVAILABLE=0
    fi

    # 检查 Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose 已安装: $COMPOSE_VERSION"
        COMPOSE_AVAILABLE=1
    elif docker compose version &> /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version)
        log_success "Docker Compose v2 已安装: $COMPOSE_VERSION"
        COMPOSE_AVAILABLE=1
    else
        log_warning "Docker Compose 未安装"
        COMPOSE_AVAILABLE=0
    fi

    # 检查 Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        log_success "Python3 已安装: $PYTHON_VERSION"
    else
        log_warning "Python3 未安装"
    fi

    # 检查 uv
    if command -v uv &> /dev/null; then
        UV_VERSION=$(uv --version)
        log_success "uv 已安装: $UV_VERSION"
    else
        log_warning "uv 未安装"
    fi

    # 检查 curl 或 wget
    if command -v curl &> /dev/null; then
        log_success "curl 已安装"
    elif command -v wget &> /dev/null; then
        log_success "wget 已安装"
    else
        log_error "curl 或 wget 未安装，请先安装"
        exit 1
    fi

    echo ""
    read -p "按 Enter 继续..."
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."

    if [ "$OS" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            apt-get update -qq
            apt-get install -y -qq curl wget unzip build-essential
        elif command -v yum &> /dev/null; then
            yum install -y -q curl wget unzip gcc
        elif command -v brew &> /dev/null; then
            brew install curl wget unzip
        fi
    fi
}

# 主函数
main() {
    case "$1" in
        package)
            log_info "启动包管理器部署..."
            source "$(dirname "$0")/install-package.sh"
            ;;
        manual)
            log_info "启动手动部署..."
            source "$(dirname "$0")/install-manual.sh"
            ;;
        docker)
            log_info "启动 Docker 部署..."
            source "$(dirname "$0")/install-docker.sh"
            ;;
        check)
            check_system
            ;;
        help|--help|-h|usage|--usage)
            show_help
            ;;
        *)
            # 显示更新日志并等待用户输入
            show_changelog
            ;;
    esac
}

# 执行主函数
main "$@"
