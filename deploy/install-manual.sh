#!/bin/bash

##############################################################################
# LangBot 手动部署脚本
# 从源码编译/下载 Release 部署 LangBot
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

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."

    mkdir -p logs
    mkdir -p data
    mkdir -p config

    log_success "目录创建完成"
}

# 安装系统依赖
install_dependencies() {
    log_info "检查/安装系统依赖..."

    OS=$(uname -s)
    if [ "$OS" = "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            log_info "检测到 Debian/Ubuntu 系统，安装依赖..."
            apt-get update -qq
            apt-get install -y -qq curl wget unzip build-essential python3 python3-pip python3-venv
        elif command -v yum &> /dev/null; then
            log_info "检测到 CentOS/RHEL 系统，安装依赖..."
            yum install -y -q curl wget unzip gcc python3 python3-pip
        elif command -v pacman &> /dev/null; then
            log_info "检测到 Arch Linux 系统，安装依赖..."
            pacman -Sy --noconfirm curl wget unzip gcc python python-pip
        fi
    elif [ "$OS" = "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            log_warning "Homebrew 未安装，请先安装 Homebrew"
            log_info "访问 https://brew.sh 了解安装方法"
            exit 1
        fi
        log_info "检测到 macOS，安装依赖..."
        brew install curl wget unzip gcc python
    fi

    log_success "系统依赖安装完成"
}

# 安装 uv
install_uv() {
    log_info "安装 uv..."

    if command -v uv &> /dev/null; then
        UV_VERSION=$(uv --version)
        log_success "uv 已安装: $UV_VERSION"
        return 0
    fi

    log_info "使用 pip3 安装 uv..."
    if command -v pip3 &> /dev/null; then
        pip3 install uv || {
            log_warning "pip3 安装失败，尝试使用国内镜像源..."
            pip3 install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
        }
    elif command -v pip &> /dev/null; then
        pip install uv || {
            log_warning "pip 安装失败，尝试使用国内镜像源..."
            pip install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
        }
    fi

    UV_VERSION=$(uv --version)
    log_success "uv 安装完成: $UV_VERSION"
}

# 下载 LangBot Release
download_langbot_release() {
    log_info "下载 LangBot Release..."

    cd "$(dirname "$0")/.."

    # 创建 LangBot 目录
    mkdir -p LangBot
    cd LangBot

    # 获取最新版本信息
    log_info "正在获取最新版本信息..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/langbot-app/LangBot/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    log_info "最新版本: $LATEST_VERSION"

    # 下载地址（使用 GitHub Release）
    DOWNLOAD_URL="https://github.com/langbot-app/LangBot/releases/download/${LATEST_VERSION}/langbot-${LATEST_VERSION}-all.zip"

    # 国内镜像优化（使用 ghproxy）
    if command -v curl &> /dev/null; then
        DOWNLOAD_URL="https://ghproxy.com/${DOWNLOAD_URL}"
    fi

    # 检查是否已存在
    if [ -f "langbot-${LATEST_VERSION}-all.zip" ]; then
        log_success "下载包已存在，跳过下载"
    else
        log_info "下载地址: $DOWNLOAD_URL"
        log_info "这可能需要几分钟，请耐心等待..."

        curl -L -o "langbot-${LATEST_VERSION}-all.zip" "$DOWNLOAD_URL"

        if [ $? -eq 0 ]; then
            log_success "下载完成"
        else
            log_error "下载失败"
            exit 1
        fi
    fi

    # 解压
    log_info "解压安装包..."
    unzip -q "langbot-${LATEST_VERSION}-all.zip"

    log_success "LangBot 下载并解压完成"
}

# 安装 Python 依赖
install_python_deps() {
    log_info "安装 Python 依赖..."

    cd "$(dirname "$0")/../LangBot"

    # 检查是否已安装依赖
    if [ -f "requirements.txt" ]; then
        log_info "使用 requirements.txt 安装依赖..."

        # 使用 uv 安装
        if command -v uv &> /dev/null; then
            uv sync
        else
            # 使用 pip 安装
            if command -v pip3 &> /dev/null; then
                pip3 install -r requirements.txt
            elif command -v pip &> /dev/null; then
                pip install -r requirements.txt
            fi
        fi

        log_success "依赖安装完成"
    else
        log_warning "未找到 requirements.txt，跳过依赖安装"
    fi
}

# 生成配置文件
generate_config() {
    log_info "生成配置文件..."

    cd "$(dirname "$0")/.."

    # 检查是否需要生成配置
    if [ ! -f "data/config.yaml" ]; then
        log_info "首次运行将自动生成配置文件"

        cd LangBot
        uv run main.py

        if [ $? -eq 0 ]; then
            log_success "配置文件生成成功"
        else
            log_error "配置文件生成失败"
            exit 1
        fi
    else
        log_success "配置文件已存在"
    fi

    cd "$(dirname "$0")/.."
}

# 启动 LangBot
start_langbot() {
    log_info "启动 LangBot..."

    cd "$(dirname "$0")/../LangBot"

    # 检查 Python 环境
    if [ -f "pyproject.toml" ]; then
        log_info "使用 uv run 启动..."
        uv run main.py
    else
        log_info "使用 python3 启动..."
        python3 main.py
    fi
}

# 后台运行
start_langbot_daemon() {
    log_info "启动 LangBot (后台运行)..."

    cd "$(dirname "$0")/../LangBot"

    LOG_FILE="../logs/langbot.log"
    PID_FILE="../logs/langbot.pid"

    # 后台运行
    nohup python3 main.py > "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"

    sleep 3

    if ps -p $PID > /dev/null; then
        log_success "LangBot 已在后台启动"
        log_info "PID: $PID"
        log_info "日志文件: $LOG_FILE"
        log_info "访问地址: http://localhost:5300"
    else
        log_error "LangBot 启动失败，请查看日志: $LOG_FILE"
        cat "$LOG_FILE"
        exit 1
    fi
}

# 停止 LangBot
stop_langbot() {
    log_info "停止 LangBot..."

    cd "$(dirname "$0")/../"

    if [ -f "logs/langbot.pid" ]; then
        PID=$(cat logs/langbot.pid)
        if ps -p $PID > /dev/null; then
            kill $PID
            log_success "LangBot 已停止"
            rm logs/langbot.pid
        else
            log_warning "LangBot 进程不存在"
        fi
    else
        # 尝试通过 ps 查找进程
        PID=$(ps aux | grep "main.py" | grep -v grep | awk '{print $2}')
        if [ -n "$PID" ]; then
            kill $PID
            log_success "LangBot 已停止"
            rm -f logs/langbot.pid
        else
            log_warning "未找到运行中的 LangBot 进程"
        fi
    fi
}

# 重启 LangBot
restart_langbot() {
    log_info "重启 LangBot..."
    stop_langbot
    sleep 2
    start_langbot_daemon
}

# 显示状态
show_status() {
    log_info "LangBot 状态:"
    echo ""

    cd "$(dirname "$0")/../"

    if [ -f "logs/langbot.pid" ]; then
        PID=$(cat logs/langbot.pid)
        if ps -p $PID > /dev/null; then
            log_success "LangBot 正在运行 (PID: $PID)"
        else
            log_warning "LangBot 未运行 (PID 文件存在但进程不存在)"
        fi
    else
        log_info "LangBot 未运行"
    fi

    echo ""
    log_info "访问地址: http://localhost:5300"
    log_info "配置文件: data/config.yaml"
    log_info "日志文件: logs/langbot.log"
}

# 显示帮助
show_help() {
    cat << EOF
LangBot 手动部署脚本

功能:
  从源码/Release 包手动部署 LangBot

命令:
  install          安装 LangBot (下载 + 解压 + 安装依赖)
  download         仅下载 Release 包
  start            启动 LangBot (前台运行)
  start-daemon     启动 LangBot (后台运行)
  stop             停止 LangBot
  restart          重启 LangBot
  status           显示状态
  help             显示帮助信息

示例:
  ./install-manual.sh install      安装 LangBot
  ./install-manual.sh download     仅下载 Release 包
  ./install-manual.sh start-daemon  后台启动 LangBot
  ./install-manual.sh status       查看状态

EOF
}

# 主函数
main() {
    case "$1" in
        install)
            create_directories
            install_dependencies
            install_uv
            download_langbot_release
            install_python_deps
            generate_config
            echo ""
            log_success "LangBot 安装完成！"
            log_info "运行 'start-daemon' 启动服务"
            ;;
        download)
            download_langbot_release
            ;;
        start)
            start_langbot
            ;;
        start-daemon)
            start_langbot_daemon
            ;;
        stop)
            stop_langbot
            ;;
        restart)
            restart_langbot
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
