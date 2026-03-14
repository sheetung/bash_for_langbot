#!/bin/bash

##############################################################################
# LangBot 一键部署脚本
# 版本：0.0.3
# 作者：sheetung
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
    echo -e "    ${GREEN}版本: 0.0.3${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}1.${NC} 包管理器部署 (PyPI + uv)"
    echo -e "${GREEN}2.${NC} 手动部署"
    echo -e "${GREEN}3.${GREEN} Docker 部署（推荐）"
    echo -e "${YELLOW}4.${NC} 配置代理"
    echo -e "${YELLOW}5.${NC} 检查系统环境 (测试内容)"
    echo -e "${RED}6.${NC} 退出"
    echo -e "${CYAN}========================================${NC}"

    read -p "$(echo -e "${CYAN}请选择部署方式 [1-6]: ${NC}")" -r choice

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
            log_info "配置代理..."
            configure_proxy
            read -p "按 Enter 继续..."
            show_menu
            ;;
        5)
            log_info "检查系统环境 (测试内容)..."
            check_system
            read -p "按 Enter 继续..."
            show_menu
            ;;
        6)
            log_info "退出脚本"
            exit 0
            ;;
        *)
            echo ""
            log_error "输入有误，请重新输入 1-6"
            read -p "按 Enter 继续..."
            show_menu
            ;;
    esac
}

# 配置代理
configure_proxy() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "    ${BLUE}配置代理${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}当前代理设置:${NC}"
    
    # 显示当前代理设置
    if [ -n "$http_proxy" ]; then
        echo -e "  HTTP代理: ${GREEN}$http_proxy${NC}"
    else
        echo -e "  HTTP代理: ${RED}未设置${NC}"
    fi
    
    if [ -n "$https_proxy" ]; then
        echo -e "  HTTPS代理: ${GREEN}$https_proxy${NC}"
    else
        echo -e "  HTTPS代理: ${RED}未设置${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "1. 设置HTTP代理"
    echo -e "2. 设置HTTPS代理"
    echo -e "3. 清除代理设置"
    echo -e "4. 返回主菜单"
    echo -e "${CYAN}========================================${NC}"
    
    read -p "$(echo -e "${CYAN}请选择操作 [1-4]: ${NC}")" -r proxy_choice
    
    case $proxy_choice in
        1)
            echo ""
            read -p "$(echo -e "${YELLOW}请输入HTTP代理地址 (例如: http://127.0.0.1:7890): ${NC}")" -r proxy_url
            if [ -n "$proxy_url" ]; then
                export http_proxy="$proxy_url"
                export HTTP_PROXY="$proxy_url"
                log_success "HTTP代理已设置为: $proxy_url"
                
                # 询问是否保存到配置文件
                read -p "$(echo -e "${YELLOW}是否保存代理设置到 ~/.bashrc? (y/n): ${NC}")" -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # 移除旧的代理设置
                    sed -i '/^export http_proxy=/d' ~/.bashrc
                    sed -i '/^export HTTP_PROXY=/d' ~/.bashrc
                    # 添加新的代理设置
                    echo "export http_proxy=\"$proxy_url\"" >> ~/.bashrc
                    echo "export HTTP_PROXY=\"$proxy_url\"" >> ~/.bashrc
                    log_success "代理设置已保存到 ~/.bashrc"
                fi
            else
                log_error "代理地址不能为空"
            fi
            ;;
        2)
            echo ""
            read -p "$(echo -e "${YELLOW}请输入HTTPS代理地址 (例如: http://127.0.0.1:7890): ${NC}")" -r proxy_url
            if [ -n "$proxy_url" ]; then
                export https_proxy="$proxy_url"
                export HTTPS_PROXY="$proxy_url"
                log_success "HTTPS代理已设置为: $proxy_url"
                
                # 询问是否保存到配置文件
                read -p "$(echo -e "${YELLOW}是否保存代理设置到 ~/.bashrc? (y/n): ${NC}")" -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # 移除旧的代理设置
                    sed -i '/^export https_proxy=/d' ~/.bashrc
                    sed -i '/^export HTTPS_PROXY=/d' ~/.bashrc
                    # 添加新的代理设置
                    echo "export https_proxy=\"$proxy_url\"" >> ~/.bashrc
                    echo "export HTTPS_PROXY=\"$proxy_url\"" >> ~/.bashrc
                    log_success "代理设置已保存到 ~/.bashrc"
                fi
            else
                log_error "代理地址不能为空"
            fi
            ;;
        3)
            echo ""
            read -p "$(echo -e "${YELLOW}确定要清除所有代理设置吗? (y/n): ${NC}")" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
                log_success "代理设置已清除"
                
                # 询问是否从配置文件中移除
                read -p "$(echo -e "${YELLOW}是否从 ~/.bashrc 中移除代理设置? (y/n): ${NC}")" -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sed -i '/^export http_proxy=/d' ~/.bashrc
                    sed -i '/^export HTTP_PROXY=/d' ~/.bashrc
                    sed -i '/^export https_proxy=/d' ~/.bashrc
                    sed -i '/^export HTTPS_PROXY=/d' ~/.bashrc
                    log_success "代理设置已从 ~/.bashrc 中移除"
                fi
            fi
            ;;
        4)
            return 0
            ;;
        *)
            log_error "无效的选择"
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

auto_install_docker() {
    log_info "开始自动化安装 Docker..."
    
    # 确保curl存在
    if ! command -v curl &> /dev/null; then
        log_info "安装必需组件 curl..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y -qq curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y -q curl
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y -q curl
        fi
    fi

    # 检测是否为中国网络环境 (国内环境返回0)
    check_china
    local IS_CHINA=$?

    # 标记官方脚本是否执行成功 (初始设为失败状态 1)
    local script_success=1

    # 尝试 1: 使用 Docker 官方脚本安装
    log_info "尝试下载 Docker 官方安装脚本..."
    if curl -fsSL --connect-timeout 10 --retry 3 -o get-docker.sh https://get.docker.com; then
        if [ $IS_CHINA -eq 0 ]; then
            log_info "国内环境，使用阿里云镜像源执行官方脚本..."
            sudo sh get-docker.sh --mirror Aliyun
            script_success=$?
        else
            log_info "海外环境，直接执行官方脚本..."
            sudo sh get-docker.sh
            script_success=$?
        fi
        rm -f get-docker.sh
    else
        log_warning "官方脚本下载失败(可能被墙)..."
    fi

    # 核心修复：如果官方脚本 下载失败 或 执行报错(例如找不到莫名其妙的插件)，启动兜底方案！
    if [ $script_success -ne 0 ]; then
        log_warning "官方脚本执行失败，自动启用原生包管理器兜底方案(仅安装核心组件)..."
        
        # 尝试 2: 原生包管理器直接配置阿里云源 (避开多余插件，最稳定)
        if command -v apt-get &> /dev/null; then
            log_info "检测到 Debian/Ubuntu 系统，正在配置阿里云源..."
            sudo apt-get update -qq
            sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/$(. /etc/os-release && echo "$ID") $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update -qq
            # 【关键】这里我们只安装最核心、最稳定的基础组件，绝不安装 docker-model-plugin 这类实验性插件
            sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
        elif command -v yum &> /dev/null; then
            log_info "检测到 CentOS/RHEL 系统，正在配置阿里云源..."
            sudo yum install -y -q yum-utils
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sudo yum install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin
        else
            log_error "不支持自动兜底的系统包管理器，请手动安装 Docker"
        fi
    fi

    # 终极验证：只认可执行文件是否存在
    if command -v docker &> /dev/null; then
        log_success "Docker 主程序安装成功"
        
        # 启动并设置开机自启
        if command -v systemctl &> /dev/null; then
            sudo systemctl enable --now docker >/dev/null 2>&1
        elif command -v service &> /dev/null; then
            sudo service docker start >/dev/null 2>&1
        fi
        
        # 配置国内镜像源
        install_add_docker_cn
        
        # 配置用户组（免 sudo）
        if ! getent group docker > /dev/null; then
            sudo groupadd docker
        fi
        sudo usermod -aG docker $USER
        log_warning "注意: 部署完成后，您可能需要注销并重新登录终端，使 Docker 权限生效。"
        return 0
    else
        log_error "Docker 安装彻底失败，请检查网络或系统依赖源是否损坏！"
        return 1
    fi
}
# 安装Docker
install_add_docker() {
    log_info "正在安装 Docker 环境..."
    
    if command -v apt &>/dev/null || command -v yum &>/dev/null || command -v dnf &>/dev/null; then
        auto_install_docker
        local ret=$?
        sleep 2
        return $ret  # 修复Bug: 必须将真实的安装结果返回给上层
    else
        # 针对 Alpine, Arch 等系统
        log_info "使用包管理器直接安装 Docker..."
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        fi
        
        case "$OS" in
            alpine)
                sudo apk add docker docker-compose
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm docker docker-compose
                ;;
            *)
                log_error "不支持自动安装的系统，请手动安装 Docker: https://docs.docker.com/engine/install/"
                return 1
                ;;
        esac
        
        if command -v docker &> /dev/null; then
            install_add_docker_cn
            log_success "Docker 安装完成"
            return 0
        else
            log_error "Docker 安装失败"
            return 1
        fi
    fi
}

# 主安装函数
install_docker() {
    if ! command -v docker &>/dev/null; then
        install_add_docker
        return $?  # 修复Bug: 将下层的成功/失败状态透传给外层
    else
        log_success "Docker 环境已经安装过了！"
        install_add_docker_cn
        return 0
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
        
        # 使用强化版的 install_docker 函数
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
    
    # 创建docker-compose.yaml文件 (去除了过时的 version 字段)
    log_info "创建 docker-compose.yaml 文件..."
    cat > docker-compose.yaml << 'EOF'
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
    
    # 检查是否为国内环境，使用国内专属加速镜像
    check_china
    local IS_CHINA=$?
    if [ $IS_CHINA -eq 0 ]; then
        log_info "检测到国内网络环境，自动配置专属加速镜像..."
        sed -i 's|image: langbot-app/langbot:latest|image: docker.langbot.app/langbot-public/rockchin/langbot:latest|g' docker-compose.yaml
        log_success "已成功配置国内镜像"
    fi
    
    # 创建数据目录
    log_info "创建数据目录..."
    mkdir -p data
    
    # 启动Docker Compose (全面加上 sudo 防止越权失败)
    log_info "正在拉取镜像并启动容器 (这可能需要几分钟)..."
    if command -v docker-compose &> /dev/null; then
        sudo docker-compose up -d
    else
        sudo docker compose up -d
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Docker Compose 启动成功"
    else
        log_error "Docker Compose 启动失败，请检查网络或 Docker 服务状态"
        cd "$CURRENT_DIR"
        return 1
    fi
    
    # 等待容器启动
    log_info "等待容器初始化..."
    sleep 5
    
    # 检查容器状态 (加上 sudo)
    if command -v docker-compose &> /dev/null; then
        sudo docker-compose ps
    else
        sudo docker compose ps
    fi
    
    cd "$CURRENT_DIR"
    
    log_success "========================================"
    log_success "🎉 LangBot Docker 部署圆满完成！"
    log_success "========================================"
    log_info "部署目录: $(pwd)/LangBot/docker"
    log_info "管理命令 (建议加上 sudo 执行):"
    log_info "  查看状态: cd LangBot/docker && sudo docker compose ps"
    log_info "  查看日志: cd LangBot/docker && sudo docker compose logs -f"
    log_info "  停止服务: cd LangBot/docker && sudo docker compose down"
    log_info "  重启服务: cd LangBot/docker && sudo docker compose restart"
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
