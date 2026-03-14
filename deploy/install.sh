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
    echo -e "${GREEN}2.${NC} 手动部署"
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
            log_info "启动 Docker 部署..."
            docker_deploy
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
    log_info "检查 uv 安装状态..."
    if command -v uv &> /dev/null; then
        log_success "uv 已安装，跳过安装步骤"
    else
        log_info "uv 未安装，准备安装..."
        
        # 使用清华源安装uv（可选）
        log_info "是否使用清华源安装依赖? (y/n)"
        read -r use_tsinghua
        if [[ $use_tsinghua =~ ^[Yy]$ ]]; then
            log_info "使用清华源..."
            if command -v pip3 &> /dev/null; then
                pip3 install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
            elif command -v pip &> /dev/null; then
                pip install uv -i https://pypi.tuna.tsinghua.edu.cn/simple
            fi
        else
            if command -v pip3 &> /dev/null; then
                pip3 install uv
            elif command -v pip &> /dev/null; then
                pip install uv
            fi
        fi
        
        if [ $? -ne 0 ]; then
            log_error "uv 安装失败"
            cd "$CURRENT_DIR"
            return 1
        fi
        
        log_success "uv 安装完成"
    fi
    
    # 同步依赖
    log_info "同步依赖..."
    
    # 检测国内环境并配置清华源
    check_china
    local IS_CHINA=$?
    if [ $IS_CHINA -eq 0 ]; then
        log_info "国内环境，使用清华源..."
        export UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
        log_success "已临时配置清华源"
    else
        log_info "非国内环境，使用默认源"
    fi

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

# 配置Docker国内镜像源
install_add_docker_cn() {
    log_info "配置 Docker 国内镜像源..."
    
    # 检测是否为中国网络环境
    local country=$(curl -s --max-time 3 ipinfo.io/country)
    
    if [ "$country" = "CN" ]; then
        log_info "国内环境，配置国内镜像源..."
        sudo mkdir -p /etc/docker
        sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.m.ixdev.cn",
    "https://hub.rat.dev",
    "https://dockerproxy.net",
    "https://docker-registry.nmqu.com",
    "https://docker.amingg.com",
    "https://docker.hlmirror.com",
    "https://hub1.nat.tf",
    "https://hub2.nat.tf",
    "https://hub3.nat.tf",
    "https://docker.m.daocloud.io",
    "https://docker.kejilion.pro",
    "https://docker.367231.xyz",
    "https://hub.1panel.dev",
    "https://dockerproxy.cool",
    "https://docker.apiba.cn",
    "https://proxy.vvvv.ee"
  ]
}
EOF
        log_success "Docker 国内镜像源配置完成"
    else
        log_info "非国内环境，使用默认镜像源"
    fi

    # 启动Docker服务
    if command -v systemctl &> /dev/null; then
        sudo systemctl enable docker
        sudo systemctl start docker
        log_success "Docker 服务已启动"
    elif command -v service &> /dev/null; then
        sudo service docker start
        log_success "Docker 服务已启动"
    fi
}

# 使用linuxmirrors安装Docker
linuxmirrors_install_docker() {
    log_info "使用 LinuxMirrors 脚本安装 Docker..."
    
    # 检测是否为中国网络环境
    local country=$(curl -s --max-time 3 ipinfo.io/country)
    
    # 确保curl存在
    if ! command -v curl &> /dev/null; then
        log_info "安装 curl..."
        if command -v apt &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y curl
        fi
    fi
    
    if [ "$country" = "CN" ]; then
        log_info "国内环境，使用华为云镜像源安装 Docker..."
        bash <(curl -sSL https://linuxmirrors.cn/docker.sh) \
          --source mirrors.huaweicloud.com/docker-ce \
          --source-registry docker.1ms.run \
          --protocol https \
          --use-intranet-source false \
          --install-latest true \
          --close-firewall false \
          --ignore-backup-tips
    else
        log_info "海外环境，使用官方源安装 Docker..."
        bash <(curl -sSL https://linuxmirrors.cn/docker.sh) \
          --source download.docker.com \
          --source-registry registry.hub.docker.com \
          --protocol https \
          --use-intranet-source false \
          --install-latest true \
          --close-firewall false \
          --ignore-backup-tips
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Docker 安装完成"
        # 配置国内镜像源
        install_add_docker_cn
        # 创建docker组（如果不存在）
        if ! getent group docker > /dev/null; then
            log_info "创建 docker 用户组..."
            sudo groupadd docker
        fi
        # 添加用户到docker组
        sudo usermod -aG docker $USER
        log_warning "请注销并重新登录以使 Docker 权限生效"
    else
        log_error "Docker 安装失败"
        return 1
    fi
}

# 安装Docker
install_add_docker() {
    log_info "正在安装 Docker 环境..."
    
    if command -v apt &>/dev/null || command -v yum &>/dev/null || command -v dnf &>/dev/null; then
        linuxmirrors_install_docker
    else
        # 针对 Alpine, Arch 等不支持 linuxmirrors 脚本的系统
        log_info "使用包管理器直接安装 Docker..."
        
        # 检测操作系统类型
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        fi
        
        case "$OS" in
            alpine)
                sudo apk add docker docker-compose
                ;;
            arch|manjaro)
                sudo pacman -S docker docker-compose
                ;;
            *)
                log_error "不支持的操作系统，请手动安装 Docker"
                log_info "请访问 https://docs.docker.com/engine/install/ 查看安装指南"
                return 1
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            install_add_docker_cn
            log_success "Docker 安装完成"
        else
            log_error "Docker 安装失败"
            return 1
        fi
    fi
    
    sleep 2
}

# 主安装函数
install_docker() {
    if ! command -v docker &>/dev/null; then
        install_add_docker
    else
        log_success "Docker 环境已经安装过了！"
        # 检查是否需要配置国内镜像源
        install_add_docker_cn
    fi
}

# Docker部署
docker_deploy() {
    log_info "========================================"
    log_info "开始 Docker 部署 LangBot"
    log_info "========================================"
    
    # 保存当前目录
    local CURRENT_DIR=$(pwd)
    
    # 检查Docker是否安装
    log_info "检查 Docker 安装状态..."
    if ! command -v docker &> /dev/null; then
        log_warning "Docker 未安装，开始自动安装..."
        
        # 使用新的install_docker函数
        if install_docker; then
            log_success "Docker 安装成功"
        else
            log_error "Docker 安装失败"
            cd "$CURRENT_DIR"
            return 1
        fi
    else
        DOCKER_VERSION=$(docker --version)
        log_success "Docker 已安装: $DOCKER_VERSION"
        # 检查是否需要配置国内镜像源
        install_add_docker_cn
    fi
    
    # 检查Docker Compose
    log_info "检查 Docker Compose 安装状态..."
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose 已安装: $COMPOSE_VERSION"
    elif docker compose version &> /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version)
        log_success "Docker Compose v2 已安装: $COMPOSE_VERSION"
    else
        log_error "Docker Compose 未安装"
        log_info "请安装 Docker Compose: https://docs.docker.com/compose/install/"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    # 创建LangBot/docker目录
    log_info "创建 LangBot/docker 目录..."
    mkdir -p LangBot/docker
    cd LangBot/docker
    
    # 创建docker-compose.yaml文件
    log_info "创建 docker-compose.yaml 文件..."
    cat > docker-compose.yaml << 'EOF'
version: '3.8'

services:
  langbot:
    image: langbot-app/langbot:latest
    container_name: langbot
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    environment:
      - TZ=Asia/Shanghai
    networks:
      - langbot-network

networks:
  langbot-network:
    driver: bridge
EOF
    
    if [ $? -eq 0 ]; then
        log_success "docker-compose.yaml 创建完成"
    else
        log_error "docker-compose.yaml 创建失败"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    # 检查是否为国内环境，使用国内镜像
    check_china
    local IS_CHINA=$?
    if [ $IS_CHINA -eq 0 ]; then
        log_info "国内环境，配置国内镜像..."
        sed -i 's|image: langbot-app/langbot:latest|image: docker.langbot.app/langbot-public/rockchin/langbot:latest|g' docker-compose.yaml
        log_success "已配置国内镜像"
    fi
    
    # 创建数据目录
    log_info "创建数据目录..."
    mkdir -p data
    
    # 启动Docker Compose
    log_info "启动 Docker Compose..."
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Docker Compose 启动成功"
    else
        log_error "Docker Compose 启动失败"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    # 等待容器启动
    log_info "等待容器启动..."
    sleep 5
    
    # 检查容器状态
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi
    
    cd "$CURRENT_DIR"
    
    log_success "========================================"
    log_success "Docker 部署完成！"
    log_success "========================================"
    log_info "部署目录: $(pwd)/LangBot/docker"
    log_info "管理命令:"
    log_info "  查看状态: cd LangBot/docker && docker compose ps"
    log_info "  查看日志: cd LangBot/docker && docker compose logs -f"
    log_info "  停止服务: cd LangBot/docker && docker compose down"
    log_info "  重启服务: cd LangBot/docker && docker compose restart"
    log_info "访问地址: http://localhost:8080"
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
