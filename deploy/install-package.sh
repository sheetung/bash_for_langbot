#!/bin/bash

##############################################################################
# LangBot 包管理器部署脚本
# 使用 PyPI + uv 部署 LangBot
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

# 安装 uv
install_uv() {
    log_info "安装 uv..."

    # 检查是否已安装
    if command -v uv &> /dev/null; then
        UV_VERSION=$(uv --version)
        log_success "uv 已安装: $UV_VERSION"
        return 0
    fi

    # 检测系统类型
    if command -v pip3 &> /dev/null; then
        log_info "使用 pip3 安装 uv..."
        pip3 install uv || {
            log_warning "pip3 安装失败，尝试使用国内镜像源..."
            pip3 install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
        }
    elif command -v pip &> /dev/null; then
        log_info "使用 pip 安装 uv..."
        pip install uv || {
            log_warning "pip 安装失败，尝试使用国内镜像源..."
            pip install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
        }
    else
        log_error "无法找到 pip，请先安装 Python 和 pip"
        exit 1
    fi

    UV_VERSION=$(uv --version)
    log_success "uv 安装完成: $UV_VERSION"
}

# 安装 LangBot
install_langbot() {
    log_info "开始安装 LangBot..."

    # 检查是否在 LangBot 目录中运行
    if [ -f "main.py" ]; then
        log_info "在 LangBot 目录中运行..."
    else
        # 创建 LangBot 目录
        mkdir -p LangBot
        cd LangBot
        log_info "创建 LangBot 工作目录"
    fi

    # 运行 uvx 安装 LangBot
    log_info "使用 uvx 安装 LangBot..."
    uvx langbot@latest

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

    cd "$(dirname "$0")/.."

    # 检查配置文件是否存在
    if [ -f "data/config.yaml" ]; then
        log_success "配置文件已存在: data/config.yaml"
    else
        log_warning "配置文件不存在，首次运行将自动生成"
    fi
}

# 启动 LangBot
start_langbot() {
    log_info "启动 LangBot..."

    cd "$(dirname "$0")/.."

    # 检查是否在 LangBot 目录
    if [ -f "LangBot/main.py" ]; then
        cd LangBot
    fi

    # 启动服务
    log_info "LangBot 将在 http://localhost:5300 启动"
    log_info "按 Ctrl+C 停止服务"

    uv run main.py

    # 保存 PID
    PID=$!
    echo $PID > ../logs/langbot.pid
    log_success "LangBot 已启动，PID: $PID"
}

# 后台运行 LangBot
start_langbot_daemon() {
    log_info "启动 LangBot (后台运行)..."

    cd "$(dirname "$0")/.."

    # 检查是否在 LangBot 目录
    if [ -f "LangBot/main.py" ]; then
        cd LangBot
    fi

    # 创建日志文件
    LOG_FILE="../logs/langbot.log"
    PID_FILE="../logs/langbot.pid"

    # 后台运行
    nohup uv run main.py > "$LOG_FILE" 2>&1 &
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

    cd "$(dirname "$0")/.."

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
        PID=$(ps aux | grep "uv run main.py" | grep -v grep | awk '{print $2}')
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
LangBot 包管理器部署脚本

功能:
  安装 LangBot 使用 PyPI + uv 方式部署

命令:
  install          安装 LangBot
  start            启动 LangBot (前台运行)
  start-daemon     启动 LangBot (后台运行)
  stop             停止 LangBot
  restart          重启 LangBot
  status           显示状态
  help             显示帮助信息

示例:
  ./install-package.sh install      安装 LangBot
  ./install-package.sh start-daemon  后台启动 LangBot
  ./install-package.sh status       查看状态

EOF
}

# 主函数
main() {
    case "$1" in
        install)
            create_directories
            install_uv
            install_langbot
            configure_langbot
            echo ""
            log_success "LangBot 安装完成！"
            log_info "运行 'start-daemon' 启动服务"
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
