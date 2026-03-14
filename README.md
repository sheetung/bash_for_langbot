# LangBot 一键部署脚本

LangBot 的自动化部署工具，支持三种部署方式：包管理器、手动部署、Docker 部署。

## 快速开始

### 方式一：curl 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/sheetung/bash_for_langbot/master/deploy/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

脚本会自动显示菜单，您只需选择对应的部署方式即可。

### 方式二：本地执行

```bash
# 进入部署目录
cd deploy

# 查看菜单
./install.sh


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
