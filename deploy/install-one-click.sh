#!/bin/bash

##############################################################################
# LangBot 一键安装脚本
# 通过 curl 直接下载并运行主脚本
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检测操作系统
detect_os() {
    OS=$(uname -s)

    case $OS in
        Linux*)
            SYSTEM="Linux"
            ;;
        Darwin*)
            SYSTEM="macOS"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            SYSTEM="Windows"
            ;;
        *)
            SYSTEM="Unknown"
            ;;
    esac

    log_info "检测到操作系统: $SYSTEM"
}

# 下载并执行主脚本
download_and_run() {
    log_info "下载 LangBot 一键部署脚本..."

    # GitHub 仓库地址（根据实际仓库地址修改）
    REPO_URL="https://raw.githubusercontent.com/sheetung/bash_for_langbot/main/deploy/install.sh"

    # 检测是否使用国内镜像加速
    if [ -f "/etc/os-release" ]; then
        if grep -qi "centos\|fedora\|rhel\|ubuntu\|debian" /etc/os-release; then
            log_info "检测到国内系统，使用 GitHub 加速下载"
        else
            log_info "使用国内镜像加速下载..."
            REPO_URL="https://ghproxy.com/${REPO_URL}"
        fi
    fi

    log_info "下载地址: $REPO_URL"

    # 下载脚本
    if command -v curl &> /dev/null; then
        curl -fsSL "$REPO_URL" -o /tmp/langbot-install.sh
    elif command -v wget &> /dev/null; then
        wget -qO /tmp/langbot-install.sh "$REPO_URL"
    else
        log_error "curl 或 wget 未安装，无法下载脚本"
        exit 1
    fi

    chmod +x /tmp/langbot-install.sh

    log_success "脚本下载完成"

    # 执行脚本
    log_info "启动部署脚本..."
    echo ""
    /tmp/langbot-install.sh

    # 清理
    rm -f /tmp/langbot-install.sh
}

# 显示使用说明
show_usage() {
    cat << EOF
========================================================================
    LangBot 一键安装脚本
========================================================================

用法:
  ./install-one-click.sh     # 下载并运行主脚本
  ./install-one-click.sh <部署方式>  # 直接使用指定部署方式
    - package: 包管理器部署
    - manual: 手动部署
    - docker: Docker 部署

示例:
  ./install-one-click.sh       # 运行主菜单
  ./install-one-click.sh docker # 直接使用 Docker 部署

========================================================================
EOF
}

# 主函数
main() {
    case "$1" in
        package|manual|docker|check)
            log_info "检测到直接部署方式参数: $1"
            detect_os

            # 创建临时目录
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"

            # 下载并执行主脚本
            REPO_URL="https://raw.githubusercontent.com/sheetung/bash_for_langbot/main/deploy/install.sh"

            if command -v curl &> /dev/null; then
                curl -fsSL "$REPO_URL" -o install.sh
            elif command -v wget &> /dev/null; then
                wget -qO install.sh "$REPO_URL"
            else
                log_error "curl 或 wget 未安装"
                exit 1
            fi

            chmod +x install.sh
            ./install.sh "$1"
            exit_code=$?

            # 清理
            cd /
            rm -rf "$TEMP_DIR"

            exit $exit_code
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            detect_os
            download_and_run
            ;;
    esac
}

# 执行主函数
main "$@"
