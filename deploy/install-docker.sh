#!/bin/bash

##############################################################################
# LangBot Docker 部署脚本
# 使用 Docker Compose 部署 LangBot（国内环境优化）
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
    mkdir -p LangBot

    log_success "目录创建完成"
}

# 检查 Docker
check_docker() {
    log_info "检查 Docker 环境..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        log_info "访问 https://docs.docker.com/get-docker/ 了解安装方法"
        exit 1
    fi

    DOCKER_VERSION=$(docker --version)
    log_success "Docker 已安装: $DOCKER_VERSION"

    # 检查 Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose 已安装: $COMPOSE_VERSION"
    elif docker compose version &> /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version)
        log_success "Docker Compose v2 已安装: $COMPOSE_VERSION"
        HAS_COMPOSE=1
    else
        log_error "Docker Compose 未安装"
        log_info "访问 https://docs.docker.com/compose/install/ 了解安装方法"
        exit 1
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
            exit 1
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
        exit 1
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
        docker compose pull
    else
        docker-compose pull
    fi

    log_success "Docker 镜像拉取完成"
}

# 启动 LangBot
start_langbot() {
    log_info "启动 LangBot 容器..."

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose up -d
    else
        docker-compose up -d
    fi

    log_success "LangBot 已启动"
}

# 停止 LangBot
stop_langbot() {
    log_info "停止 LangBot 容器..."

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose down
    else
        docker-compose down
    fi

    log_success "LangBot 已停止"
}

# 重启 LangBot
restart_langbot() {
    log_info "重启 LangBot 容器..."
    stop_langbot
    sleep 2
    start_langbot
}

# 查看状态
show_status() {
    log_info "LangBot 状态:"
    echo ""

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose ps
    else
        docker-compose ps
    fi

    echo ""
    log_info "访问地址: http://localhost:5300"
    log_info "配置目录: ../../data"
    log_info "日志目录: ../../logs"
}

# 查看日志
show_logs() {
    log_info "显示 LangBot 日志..."

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose logs -f
    else
        docker-compose logs -f
    fi
}

# 重建容器
rebuild_langbot() {
    log_info "重建 LangBot 容器..."

    cd "$(dirname "$0")/../LangBot/docker"

    if [ "$HAS_COMPOSE" = 1 ]; then
        docker compose down
        docker compose pull
        docker compose up -d
    else
        docker-compose down
        docker-compose pull
        docker-compose up -d
    fi

    log_success "LangBot 已重建"
}

# 重置配置（保留数据）
reset_config() {
    log_warning "重置配置将删除当前配置，保留数据目录"

    read -p "确认重置配置？(y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$(dirname "$0")/../LangBot/docker"

        if [ "$HAS_COMPOSE" = 1 ]; then
            docker compose down
            docker compose up -d
        else
            docker-compose down
            docker-compose up -d
        fi

        log_success "LangBot 已重建"
    else
        log_info "取消重置配置"
    fi
}

# 显示帮助
show_help() {
    cat << EOF
LangBot Docker 部署脚本

功能:
  使用 Docker Compose 部署 LangBot（国内环境优化）

命令:
  install          安装并启动 LangBot
  start            启动 LangBot
  stop             停止 LangBot
  restart          重启 LangBot
  status           显示容器状态
  logs             查看日志
  rebuild          重建容器
  reset-config     重置配置（保留数据）
  help             显示帮助信息

配置:
  镜像源: docker.langbot.app/langbot-public/rockchin/langbot:latest
  端口: 5300 (WebUI), 2280-2290 (OneBot)

示例:
  ./install-docker.sh install      安装并启动
  ./install-docker.sh status       查看状态
  ./install-docker.sh logs         查看日志

EOF
}

# 主函数
main() {
    case "$1" in
        install)
            create_directories
            check_docker
            clone_langbot_repo
            configure_docker_compose
            pull_docker_image
            start_langbot
            echo ""
            log_success "LangBot 安装并启动完成！"
            log_info "运行 'status' 查看状态"
            ;;
        start)
            start_langbot
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
        logs)
            show_logs
            ;;
        rebuild)
            rebuild_langbot
            ;;
        reset-config)
            reset_config
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
