# LangBot 一键部署脚本

LangBot 的自动化部署工具，支持三种部署方式：包管理器、手动部署、Docker 部署。

## 快速开始

### 方式一：curl 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/sheetung/bash_for_langbot/master/deploy/install.sh | bash
```

脚本会自动显示菜单，您只需选择对应的部署方式即可。

### 方式二：本地执行

```bash
# 进入部署目录
cd deploy

# 查看菜单
./install.sh
# 选择部署方式后自动进入对应安装流程

# 或直接使用对应部署方式
./install-package.sh install    # 包管理器部署
./install-manual.sh install     # 手动部署
./install-docker.sh install     # Docker 部署

# 查看帮助
./install.sh help
```

## 部署方式对比

| 特性 | 包管理器 | 手动部署 | Docker |
|------|---------|---------|--------|
| 系统依赖 | 需要 uv | 需要 uv + 系统依赖 | 需要 Docker |
| 启动速度 | 快 | 中等 | 快 |
| 配置管理 | 简单 | 复杂 | 简单 |
| 生产推荐 | ❌ | ❌ | ✅ |
| 测试推荐 | ✅ | ✅ | ✅ |

## 目录结构

```
bash_for_langbot/
├── deploy/
│   ├── install.sh              # 主脚本（菜单）
│   ├── install-one-click.sh    # 一键安装脚本
│   ├── install-package.sh      # 包管理器部署
│   ├── install-manual.sh       # 手动部署
│   └── install-docker.sh       # Docker 部署
├── logs/                       # 日志目录
├── data/                       # 数据目录
├── config/                     # 配置目录
└── LangBot/                    # LangBot 工作目录（Docker 部署时自动创建）
```

## 部署命令说明

### 主脚本

```bash
./deploy/install.sh            # 显示菜单
./deploy/install.sh check      # 检查系统环境
./deploy/install.sh package    # 直接使用包管理器部署
./deploy/install.sh manual     # 直接使用手动部署
./deploy/install.sh docker     # 直接使用 Docker 部署
```

### 包管理器部署

```bash
./deploy/install-package.sh install      # 安装 LangBot
./deploy/install-package.sh start        # 启动（前台）
./deploy/install-package.sh start-daemon # 启动（后台）
./deploy/install-package.sh stop         # 停止
./deploy/install-package.sh restart      # 重启
./deploy/install-package.sh status       # 查看状态
```

### 手动部署

```bash
./deploy/install-manual.sh install       # 安装 LangBot
./deploy/install-manual.sh download      # 仅下载 Release 包
./deploy/install-manual.sh start         # 启动（前台）
./deploy/install-manual.sh start-daemon  # 启动（后台）
./deploy/install-manual.sh stop          # 停止
./deploy/install-manual.sh restart       # 重启
./deploy/install-manual.sh status        # 查看状态
```

### Docker 部署

```bash
./deploy/install-docker.sh install        # 安装并启动
./deploy/install-docker.sh start         # 启动
./deploy/install-docker.sh stop          # 停止
./deploy/install-docker.sh restart       # 重启
./deploy/install-docker.sh status        # 查看状态
./deploy/install-docker.sh logs          # 查看日志
./deploy/install-docker.sh rebuild       # 重建容器
./deploy/install-docker.sh reset-config  # 重置配置
```

## 国内环境优化

Docker 部署已针对国内环境优化：

- ✅ 使用国内镜像源：`docker.langbot.app/langbot-public/rockchin/langbot:latest`
- ✅ 自动克隆仓库（使用 Gitee 镜像加速）
- ✅ 配置文件备份机制

如需切换回官方镜像源，编辑 `LangBot/docker/docker-compose.yaml`：

```yaml
services:
  langbot:
    image: docker.langbot.app/langbot-public/rockchin/langbot:latest  # 国内镜像
    # image: ghcr.io/langbot-app/langbot:latest  # 官方镜像
```

## 访问地址

| 部署方式 | WebUI 地址 | OneBot 端口 |
|---------|-----------|------------|
| 包管理器 | http://localhost:5300 | - |
| 手动部署 | http://localhost:5300 | - |
| Docker | http://localhost:5300 | 2280-2290 |

## 系统要求

### 包管理器/手动部署

- **操作系统**：Windows, Linux, macOS
- **Python**：3.8+
- **uv**：自动安装
- **依赖**：
  - Linux: curl, wget, unzip, build-essential
  - macOS: Homebrew
  - Windows: 无需额外工具

### Docker 部署

- **Docker**：20.10+
- **Docker Compose**：2.0+
- **系统**：支持 Linux, macOS, Windows (with Docker Desktop)

## 常见问题

### 1. 权限问题

Linux/macOS 可能需要执行权限：
```bash
chmod +x deploy/*.sh
```

### 2. sudo 权限

脚本会在需要时自动提示输入 sudo 权限。

### 3. 端口占用

如果端口 5300 被占用，修改配置文件：

**包管理器/手动部署**：编辑 `data/config.yaml`
**Docker**：编辑 `LangBot/docker/docker-compose.yaml`

### 4. 更新 LangBot

- **包管理器**：`./deploy/install-package.sh restart`
- **手动部署**：`./deploy/install-manual.sh download && ./deploy/install-manual.sh restart`
- **Docker**：`./deploy/install-docker.sh rebuild`

## 配置文件

配置文件位置：

| 部署方式 | 路径 |
|---------|------|
| 包管理器 | `data/config.yaml` |
| 手动部署 | `data/config.yaml` |
| Docker | `LangBot/docker/data/config.yaml` |

首次运行会自动生成配置文件。

## 日志文件

日志位置：

| 部署方式 | 路径 |
|---------|------|
| 包管理器 | `logs/langbot.log` |
| 手动部署 | `logs/langbot.log` |
| Docker | `LangBot/docker/logs` |

## 支持

- **官方文档**：https://docs.langbot.app
- **GitHub 仓库**：https://github.com/langbot-app/LangBot
- **问题反馈**：https://github.com/langbot-app/LangBot/issues

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
