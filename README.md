# LangBot 一键部署脚本

LangBot 的自动化部署工具，支持三种部署方式：包管理器、手动部署、Docker 部署。

## 快速开始

### curl 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/sheetung/bash_for_langbot/master/deploy/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

脚本会自动显示菜单，您只需选择对应的部署方式即可。


## 功能特性

- ✅ 三种部署方式：包管理器、手动部署、Docker 部署
- ✅ 国内环境优化（镜像源加速）
- ✅ 智能错误处理（失败时返回菜单，不直接退出）
- ✅ 完整的服务管理（启动、停止、重启、状态）
- ✅ 系统环境自动检查
- ✅ 后台运行支持
- [] 详细的日志和状态管理

## 配置文件

配置文件位置：

| 部署方式 | 路径 |
|---------|------|
| 包管理器 | `data/config.yaml` |
| 手动部署 | `data/config.yaml` |
| Docker | `LangBot/docker/data/config.yaml` |

首次运行会自动生成配置文件。


## 支持

- **官方文档**：https://docs.langbot.app
- **GitHub 仓库**：https://github.com/langbot-app/LangBot
- **问题反馈**：https://github.com/langbot-app/LangBot/issues

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！