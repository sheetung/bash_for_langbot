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
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# 检测是否在中国大陆
check_china() {
    # 使用 ipinfo.io 获取国家代码
    log_info "检测网络环境..."
    COUNTRY=$(curl -s ipinfo.io/country)
    
    if [ "$COUNTRY" = "CN" ]; then
        log_info "检测到中国大陆网络环境 (国家代码: $COUNTRY)"
        
        # 检测是否能访问外网
        if curl -s --connect-timeout 3 github.com > /dev/null 2>&1; then
            log_info "但可以访问外网，使用原始源"
            return 1  # 返回1表示不使用国内镜像
        else
            log_info "无法访问外网，使用国内镜像"
            return 0  # 返回0表示使用国内镜像
        fi
    else
        log_info "检测到非中国大陆网络环境 (国家代码: $COUNTRY)"
        return 1
    fi
}

# 显示更新日志
show_changelog() {
    show_menu
}

# 显示菜单
show_menu() {
    # 获取脚本所在目录的绝对路径
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "    ${PURPLE}LangBot 一键部署脚本${NC}"
    echo -e "    ${YELLOW}版本: 1.0.0${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}1.${NC} 包管理器部署 (PyPI + uv)"
    echo -e "${GREEN}2.${NC} 手动部署 (源码编译)"
    echo -e "${GREEN}3.${NC} Docker 部署 (推荐)"
    echo -e "${GREEN}4.${NC} 检查系统环境"
    echo -e "${GREEN}5.${NC} 退出"
    echo -e "${CYAN}========================================${NC}"
    
    # 从终端读取输入
    read -p "$(echo -e "${CYAN}请选择部署方式 [1-5]: ${NC}")" -r choice
    
    # 保存原始输入
    original_choice="$choice"
    # 确保original_choice不为空
    if [ -z "$original_choice" ]; then
        original_choice="<空输入>"
    fi
    
    # 清理输入，移除可能的多余字符
    choice=$(echo "$choice" | tr -d '\r' | tr -d '\n' | sed 's/[^0-9]*//g')
    echo "DEBUG: choice='$choice'"
    
    # 检查输入是否为空
    if [ -z "$choice" ]; then
        echo ""
        log_error "您输入的是: '$original_choice'"
        log_error "输入有误，请重新输入 1-5"
        read -p "按 Enter 继续..."
        show_menu
        return
    fi
    
    case $choice in
        1)
            log_info "启动包管理器部署..."
            create_directories || { log_error "创建目录失败"; show_menu; return; }
            install_uv || { log_error "安装 uv 失败"; show_menu; return; }
            install_langbot || { log_error "安装 LangBot 失败"; show_menu; return; }
            configure_langbot || { log_error "配置 LangBot 失败"; show_menu; return; }
            echo ""
            log_success "LangBot 安装完成！"
            log_info "运行 'start-daemon' 启动服务"
            read -p "按 Enter 继续..."
            show_menu
            ;;
        2)
            log_info "启动手动部署..."
            manual_deploy || { log_error "手动部署失败"; show_menu; return; }
            read -p "按 Enter 继续..."
            show_menu
            ;;
        3)
            log_info "启动 Docker 部署..."
            docker_deploy || { log_error "Docker 部署失败"; show_menu; return; }
            read -p "按 Enter 继续..."
            show_menu
            ;;
        4)
            log_info "检查系统环境..."
            check_system
            read -p "按 Enter 继续..."
            show_menu
            ;;
        5)
            log_info "退出脚本"
            exit 0
            ;;
        *)
            echo ""
            log_error "您输入的是: '$original_choice'"
            log_error "输入有误，请重新输入 1-5"
            read -p "按 Enter 继续..."
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
    echo -e "${CYAN}========================================${NC}"
    echo -e "    ${PURPLE}系统环境检查${NC}"
    echo -e "${CYAN}========================================${NC}"

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
        return 1
    fi

    echo ""
    read -p "$(echo -e "${CYAN}按 Enter 继续...${NC}")"
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

# 包管理器部署相关函数

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."

    # 确保在正确的工作目录
    if [ ! -d "LangBot" ]; then
        mkdir -p LangBot || return 1
    fi
    
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

    # 检测是否在中国大陆
    check_china
    IS_CHINA=$?

    # 安装 uv
    if command -v pip3 &> /dev/null; then
        if [ $IS_CHINA -eq 0 ]; then
            log_info "使用 pip3 安装 uv (清华源)..."
            pip3 install uv -i https://pypi.tuna.tsinghua.edu.cn/simple || return 1
        else
            log_info "使用 pip3 安装 uv..."
            pip3 install uv || return 1
        fi
    elif command -v pip &> /dev/null; then
        if [ $IS_CHINA -eq 0 ]; then
            log_info "使用 pip 安装 uv (清华源)..."
            pip install uv -i https://pypi.tuna.tsinghua.edu.cn/simple || return 1
        else
            log_info "使用 pip 安装 uv..."
            pip install uv || return 1
        fi
    else
        log_error "无法找到 pip，请先安装 Python 和 pip"
        return 1
    fi

    UV_VERSION=$(uv --version)
    log_success "uv 安装完成: $UV_VERSION"
}

# 安装 LangBot
install_langbot() {
    log_info "开始安装 LangBot..."

    # 确保在 LangBot 目录中
    if [ ! -d "LangBot" ]; then
        mkdir -p LangBot
    fi
    
    cd LangBot
    log_info "在 LangBot 目录中安装..."

    # 检测是否在中国大陆
    check_china
    IS_CHINA=$?

    # 运行 uvx 安装 LangBot
    log_info "使用 uvx 安装 LangBot..."
    if [ $IS_CHINA -eq 0 ]; then
        log_info "使用国内源加速下载..."
        # 设置国内PyPI镜像
        export UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
        uvx langbot@latest || return 1
    else
        uvx langbot@latest || return 1
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

    # 确保在 LangBot 目录中
    if [ ! -d "LangBot" ]; then
        mkdir -p LangBot
    fi
    
    cd LangBot
    
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

    # 确保在 LangBot 目录中
    if [ ! -d "LangBot" ]; then
        log_error "LangBot 目录不存在，请先安装"
        return 1
    fi
    
    cd LangBot

    # 启动服务
    log_info "LangBot 将在 http://localhost:5300 启动"
    log_info "按 Ctrl+C 停止服务"

    uv run main.py

    # 保存 PID
    PID=$!
    echo $PID > logs/langbot.pid
    log_success "LangBot 已启动，PID: $PID"
}

# 后台运行 LangBot
start_langbot_daemon() {
    log_info "启动 LangBot (后台运行)..."

    # 确保在 LangBot 目录中
    if [ ! -d "LangBot" ]; then
        log_error "LangBot 目录不存在，请先安装"
        return 1
    fi
    
    cd LangBot

    # 创建日志文件
    LOG_FILE="logs/langbot.log"
    PID_FILE="logs/langbot.pid"

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
        return 1
    fi
}

# 停止 LangBot
stop_langbot() {
    log_info "停止 LangBot..."

    # 确保在 LangBot 目录中
    if [ ! -d "LangBot" ]; then
        log_error "LangBot 目录不存在"
        return 1
    fi
    
    cd LangBot

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

    # 确保在 LangBot 目录中
    if [ ! -d "LangBot" ]; then
        log_error "LangBot 目录不存在"
        return 1
    fi
    
    cd LangBot

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

# 手动部署相关函数

# 安装系统依赖（手动部署）
install_manual_dependencies() {
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
            return 1
        fi
        log_info "检测到 macOS，安装依赖..."
        brew install curl wget unzip gcc python
    fi

    log_success "系统依赖安装完成"
}

# 下载 LangBot Release
download_langbot_release() {
    log_info "下载 LangBot Release..."

    # 保存当前目录
    CURRENT_DIR=$(pwd)
    
    cd "$(dirname "$0")/.."

    # 创建 LangBot 目录
    if mkdir -p LangBot; then
        log_info "LangBot 目录创建成功"
    else
        log_error "无法创建 LangBot 目录 (权限不足)"
        log_info "请尝试使用 sudo 运行脚本，或确保当前用户有目录创建权限"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    if cd LangBot; then
        log_info "进入 LangBot 目录成功"
    else
        log_error "无法进入 LangBot 目录"
        cd "$CURRENT_DIR"
        return 1
    fi

    # 获取最新版本信息
    log_info "正在获取最新版本信息..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/langbot-app/LangBot/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_VERSION" ]; then
        log_error "获取版本信息失败"
        cd "$CURRENT_DIR"
        return 1
    fi
    log_info "最新版本: $LATEST_VERSION"

    # 下载地址（使用 GitHub Release）
    DOWNLOAD_URL="https://github.com/langbot-app/LangBot/releases/download/${LATEST_VERSION}/langbot-${LATEST_VERSION}-all.zip"

    # 国内镜像优化（使用 ghproxy）
    check_china
    IS_CHINA=$?
    if [ $IS_CHINA -eq 0 ]; then
        DOWNLOAD_URL="https://gh-proxy.com/${DOWNLOAD_URL}"
        log_info "使用国内镜像加速: $DOWNLOAD_URL"
    fi

    # 检查是否已存在
    if [ -f "langbot-${LATEST_VERSION}-all.zip" ]; then
        log_success "下载包已存在，跳过下载"
    else
        log_info "下载地址: $DOWNLOAD_URL"
        log_info "这可能需要几分钟，请耐心等待..."
        log_info "正在下载中，请勿中断..."

        # 使用 --progress-bar 显示下载进度，--max-time 设置最大下载时间（10分钟）
        curl -L --progress-bar -o "langbot-${LATEST_VERSION}-all.zip" "$DOWNLOAD_URL"
        CURL_EXIT_CODE=$?

        if [ $CURL_EXIT_CODE -eq 0 ]; then
            log_success "下载完成"
        elif [ $CURL_EXIT_CODE -eq 28 ]; then
            log_error "下载超时，请检查网络连接或稍后重试"
            cd "$CURRENT_DIR"
            return 1
        else
            log_error "下载失败 (错误码: $CURL_EXIT_CODE)"
            cd "$CURRENT_DIR"
            return 1
        fi
    fi

    # 解压
    log_info "解压安装包..."
    if unzip -q "langbot-${LATEST_VERSION}-all.zip"; then
        log_success "解压完成"
    else
        log_error "解压失败"
        cd "$CURRENT_DIR"
        return 1
    fi

    # 回到原来的目录
    cd "$CURRENT_DIR"
    
    log_success "LangBot 下载并解压完成"
}

# 生成配置文件（手动部署）
generate_config() {
    log_info "生成配置文件..."

    # 保存当前工作目录
    CURRENT_DIR=$(pwd)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

    cd "$BASE_DIR"

    # 检查是否需要生成配置
    if [ ! -f "data/config.yaml" ]; then
        log_info "首次运行将自动生成配置文件"

        cd "$BASE_DIR/LangBot"

        # 检查 uv 是否安装
        if command -v uv &> /dev/null; then
            uv run main.py
        else
            log_warning "uv 未安装，使用 python3 替代"
            python3 main.py
        fi

        if [ $? -eq 0 ]; then
            log_success "配置文件生成成功"
        else
            log_error "配置文件生成失败"
            cd "$CURRENT_DIR"
            return 1
        fi
    else
        log_success "配置文件已存在"
    fi

    # 返回原始目录
    cd "$CURRENT_DIR"
}

# 手动部署 LangBot
manual_deploy() {
    log_info "========================================"
    log_info "开始手动部署 LangBot..."
    log_info "此过程可能需要几分钟，请耐心等待"
    log_info "========================================"
    echo ""

    # 保存脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

    log_info "步骤 1/4: 创建目录结构..."
    cd "$BASE_DIR"
    create_directories || { log_error "创建目录失败"; return 1; }
    log_success "目录创建完成"
    echo ""

    log_info "步骤 2/4: 下载 LangBot Release..."
    log_info "正在从 GitHub 下载最新版本..."
    cd "$BASE_DIR"
    download_langbot_release || { log_error "下载 LangBot Release 失败"; return 1; }
    log_success "下载并解压完成"
    echo ""

    log_info "步骤 3/4: 检查 Python 依赖..."
    cd "$BASE_DIR/LangBot"

    # 检查是否包含虚拟环境
    if [ ! -d "venv" ]; then
        log_info "未找到虚拟环境，正在创建..."
        python3 -m venv venv || { log_error "创建虚拟环境失败"; cd "$BASE_DIR"; return 1; }
        log_success "虚拟环境创建完成"

        # 激活虚拟环境并安装依赖
        log_info "安装 Python 依赖..."
        source venv/bin/activate || { log_error "激活虚拟环境失败"; deactivate; cd "$BASE_DIR"; return 1; }
        pip install -r requirements.txt || { log_error "安装依赖失败"; deactivate; cd "$BASE_DIR"; return 1; }
        deactivate
        log_success "依赖安装完成"
    else
        log_success "虚拟环境已存在"
        log_info "检查 requirements.txt 是否存在..."
        if [ -f "requirements.txt" ]; then
            log_info "运行 pip install -r requirements.txt..."
            source venv/bin/activate || { log_error "激活虚拟环境失败"; deactivate; cd "$BASE_DIR"; return 1; }
            pip install -r requirements.txt || { log_error "更新依赖失败"; deactivate; cd "$BASE_DIR"; return 1; }
            deactivate
            log_success "依赖检查完成"
        else
            log_warning "未找到 requirements.txt，跳过依赖检查"
        fi
    fi
    cd "$BASE_DIR"
    echo ""

    log_info "步骤 4/4: 生成配置文件..."
    generate_config || { log_error "生成配置文件失败"; return 1; }
    log_success "配置生成完成"
    echo ""

    log_info "========================================"
    log_success "LangBot 手动部署完成！"
    log_info "========================================"
    log_info "运行 './install.sh start-daemon' 启动服务"
    log_info "或运行 './install.sh start' 前台启动查看日志"
}

# Docker 部署相关函数

# 检查 Docker
check_docker() {
    log_info "检查 Docker 环境..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        log_info "访问 https://docs.docker.com/get-docker/ 了解安装方法"
        return 1
    fi

    DOCKER_VERSION=$(docker --version)
    log_success "Docker 已安装: $DOCKER_VERSION"

    # 检查 Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose 已安装: $COMPOSE_VERSION"
        export HAS_COMPOSE=0
    elif docker compose version &> /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version)
        log_success "Docker Compose v2 已安装: $COMPOSE_VERSION"
        export HAS_COMPOSE=1
    else
        log_error "Docker Compose 未安装"
        log_info "访问 https://docs.docker.com/compose/install/ 了解安装方法"
        return 1
    fi
}

# 克隆 LangBot 仓库
clone_langbot_repo() {
    log_info "克隆 LangBot 仓库..."

    cd "$(dirname "$0")/../LangBot"

    if [ -d "docker" ]; then
        log_success "LangBot 仓库已存在"
    else
        # 使用国内镜像加速
        if command -v git &> /dev/null; then
            log_info "使用国内镜像克隆仓库..."

            # 尝试使用 gitee 镜像
            git clone --depth 1 https://gitee.com/mirrors/LangBot.git . 2>/dev/null || {
                log_warning "Gitee 镜像不可用，使用 GitHub 原始仓库"
                git clone --depth 1 https://github.com/langbot-app/LangBot.git .
            }
        else
            log_error "git 未安装，请先安装 git"
            return 1
        fi

        log_success "LangBot 仓库克隆完成"
    fi
}

# 配置 Docker Compose（国内环境优化）
configure_docker_compose() {
    log_info "配置 Docker Compose（国内环境优化）..."

    cd "$(dirname "$0")/../LangBot"

    # 检查 docker-compose.yaml 是否存在
    if [ ! -f "docker/docker-compose.yaml" ]; then
        log_error "docker-compose.yaml 不存在"
        return 1
    fi

    # 备份原始配置
    if [ ! -f "docker/docker-compose.yaml.backup" ]; then
        cp docker/docker-compose.yaml docker/docker-compose.yaml.backup
        log_info "已备份原始配置"
    fi

    # 国内镜像源配置
    log_info "配置国内镜像源..."

    # 替换镜像源
    if command -v sed &> /dev/null; then
        # 使用国内镜像
        sed -i 's|docker.langbot.app/langbot-public/rockchin/langbot:latest|docker.langbot.app/langbot-public/rockchin/langbot:latest|g' docker/docker-compose.yaml
    elif command -v gsed &> /dev/null; then
        sed -i 's|docker.langbot.app/langbot-public/rockchin/langbot:latest|docker.langbot.app/langbot-public/rockchin/langbot:latest|g' docker/docker-compose.yaml
    else
        log_warning "sed 不可用，请手动修改 docker/docker-compose.yaml"
        log_info "将镜像源替换为: docker.langbot.app/langbot-public/rockchin/langbot:latest"
    fi

    log_success "Docker Compose 配置完成"
}

# 拉取 Docker 镜像
pull_docker_image() {
    log_info "拉取 Docker 镜像..."

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose pull || return 1
    else
        docker-compose pull || return 1
    fi

    log_success "Docker 镜像拉取完成"
}

# 启动 LangBot（Docker）
start_langbot_docker() {
    log_info "启动 LangBot 容器..."

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose up -d
    else
        docker-compose up -d
    fi

    log_success "LangBot 已启动"
}

# Docker 部署 LangBot
docker_deploy() {
    log_info "开始 Docker 部署 LangBot..."

    create_directories || { log_error "创建目录失败"; return 1; }
    check_docker || { log_error "检查 Docker 环境失败"; return 1; }
    clone_langbot_repo || { log_error "克隆 LangBot 仓库失败"; return 1; }
    configure_docker_compose || { log_error "配置 Docker Compose 失败"; return 1; }
    pull_docker_image || { log_error "拉取 Docker 镜像失败"; return 1; }
    start_langbot_docker || { log_error "启动 LangBot 容器失败"; return 1; }

    echo ""
    log_success "LangBot Docker 部署完成！"
    log_info "运行 'docker status' 查看状态"
}

# 主函数
main() {
    case "$1" in
        package)
            log_info "启动包管理器部署..."
            create_directories
            install_uv
            install_langbot
            configure_langbot
            echo ""
            log_success "LangBot 安装完成！"
            log_info "运行 'start-daemon' 启动服务"
            ;;
        manual)
            log_info "启动手动部署..."
            manual_deploy
            ;;
        docker)
            log_info "启动 Docker 部署..."
            docker_deploy
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
        docker-start)
            log_info "启动 LangBot Docker 容器..."
            start_langbot_docker
            ;;
        docker-stop)
            log_info "停止 LangBot Docker 容器..."
            cd "$(dirname "$0")/../LangBot/docker"
            if [ "$HAS_COMPOSE" = 1 ]; then
                docker compose down
            else
                docker-compose down
            fi
            log_success "LangBot 容器已停止"
            ;;
        docker-restart)
            log_info "重启 LangBot Docker 容器..."
            cd "$(dirname "$0")/../LangBot/docker"
            if [ "$HAS_COMPOSE" = 1 ]; then
                docker compose down
                docker compose up -d
            else
                docker-compose down
                docker-compose up -d
            fi
            log_success "LangBot 容器已重启"
            ;;
        docker-status)
            log_info "查看 LangBot Docker 容器状态..."
            cd "$(dirname "$0")/../LangBot/docker"
            if [ "$HAS_COMPOSE" = 1 ]; then
                docker compose ps
            else
                docker-compose ps
            fi
            ;;
        docker-logs)
            log_info "查看 LangBot Docker 容器日志..."
            cd "$(dirname "$0")/../LangBot/docker"
            if [ "$HAS_COMPOSE" = 1 ]; then
                docker compose logs -f
            else
                docker-compose logs -f
            fi
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
