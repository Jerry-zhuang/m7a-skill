<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
  <img src="https://img.shields.io/badge/OpenClaw-Hermes-opencode-Claude_Code-8A2BE2" alt="Multi-Agent">
  <img src="https://img.shields.io/badge/Docker-20.10%2B-2496ED?logo=docker" alt="Docker">
  <img src="https://img.shields.io/github/stars/Jerry-zhuang/m7a-skill?style=social" alt="GitHub Stars">
</p>

# M7A Skill — 三月七小助手 Docker 多账号自动部署

基于 [March7thAssistant](https://github.com/moesnow/March7thAssistant) 的 Docker 多账号部署方案，支持通过 OpenClaw / Hermes / opencode / Claude Code 等 AI 编码代理以自然语言触发任务执行和账号管理。每个游戏账号运行一个独立容器，互不干扰。

---

## 功能特性

- **多账号云游戏** — 每个账号独立容器，支持 N 个账号并行管理
- **全自动任务** — 日常实训、清体力、模拟宇宙、锄大地、混沌回忆等全自动执行
- **Docker 部署** — 一键拉取镜像，Compose 编排，快速启停
- **消息通知** — 支持 Telegram 等渠道推送任务结果和扫码登录
- **定时调度** — 内置 cron 定时任务 + `after_finish: Loop` 循环模式
- **自然语言触发** — 在 AI 代理中用中文描述任务，自动映射为 CLI 命令（支持 OpenClaw / Hermes / opencode / Claude Code）

---

## 一键安装

本 skill 可同时适配以下 AI 编码代理：

| 代理 | 标识 | 安装方式 |
|------|------|----------|
| **OpenClaw** | 🦞 龙虾 | `openclaw skills add` / 终端脚本 |
| **Hermes** | 🎩 爱马仕 | `hermes skills install <URL>` / 终端脚本 |
| **opencode** | 🤖 | 终端脚本 / 手动 |
| **Claude Code** | 🟢 | 终端脚本 / 手动 |

### 🚀 终端一键安装（全平台自动检测）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/install.sh)
```

脚本会自动检测当前环境中已安装的 AI 代理，将 skill 安装到对应位置。

### 🦞 OpenClaw（龙虾）

```bash
# 方式 A：CLI 安装（推荐）
openclaw skills add https://github.com/Jerry-zhuang/m7a-skill

# 方式 B：在 OpenClaw 聊天框中粘贴此指令
#   "请从 GitHub 安装 m7a skill，仓库地址是：
#    https://github.com/Jerry-zhuang/m7a-skill"
```

### 🎩 Hermes（爱马仕）

```bash
# Hermes 支持直接从 URL 安装 SKILL.md
hermes skills install https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/skills/m7a/SKILL.md
```

### 🤖 opencode

```bash
# 项目内安装（opencode 读取 .opencode/skills/）
mkdir -p .opencode/skills
ln -sf "$(pwd)/skills/m7a" .opencode/skills/m7a
```

### 🟢 Claude Code

```bash
# 用户级安装（所有项目可用）
ln -sf "$(pwd)/skills/m7a" ~/.claude/skills/m7a

# 或项目级安装
mkdir -p .claude/skills
ln -sf "$(pwd)/skills/m7a" .claude/skills/m7a
```

---

## 前置条件

- Docker Engine >= 20.10
- Docker Compose V2（`docker-compose` 命令，非旧版 `docker-compose`）
- 足够的磁盘空间存放浏览器 Profile 和日志（每个账号约 500MB+）

---

## 快速开始

### 1. 配置

复制模板配置文件：

```bash
cp -r m7a-data/template m7a-data/accounts/main
```

编辑 `m7a-data/accounts/main/config.yaml`，填入关键配置（通知推送至少填一项，否则无法接收登录二维码）。完整配置选项参考 [config.example.yaml](https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml)。

### 2. 启动

取消 `docker-compose.yml` 中 `m7a-main` 服务的注释，然后：

```bash
docker-compose up -d
```

### 3. 登录

首次启动会弹出浏览器窗口显示 QR 码。如果配置了通知推送，二维码会自动推送到你的手机，扫码完成登录。之后容器会切换为 headless 模式自动运行。

> 详细首次登录流程见下方"首次登录"章节。

---

## 多账号管理

### 添加账号

```bash
# 1. 创建账号配置目录
mkdir -p m7a-data/accounts/alt-1

# 2. 复制配置文件
cp m7a-data/template/config.yaml m7a-data/accounts/alt-1/

# 3. 在 docker-compose.yml 中复制一份服务定义，修改：
#    - container_name: m7a-alt-1
#    - 端口递增（main 用 9222，alt-1 用 9223，以此类推）
#    - volumes 路径指向 m7a-data/accounts/alt-1/

# 4. 启动
docker-compose up -d
```

账号命名规则：小写字母 + 数字 + 连字符，2-30 个字符。

### 列出账号

```bash
docker-compose ps
```

### 删除账号

```bash
docker-compose down m7a-{account-name}
rm -rf m7a-data/accounts/{account-name}
```

---

## 任务触发

在 AI 代理（OpenClaw / Hermes / opencode / Claude Code）中使用自然语言描述任务，系统会自动映射到容器内 CLI 命令并执行。

| 你说 | 实际执行 |
|---|---|
| "今天日常做了吗" | `docker exec m7a-{name} python main.py daily` |
| "清一下体力" | `docker exec m7a-{name} python main.py power` |
| "跑一轮全部" | `docker exec m7a-{name} python main.py` |
| "打模拟宇宙" | `docker exec m7a-{name} python main.py universe` |
| "锄大地" | `docker exec m7a-{name} python main.py fight` |
| "差分宇宙" | `docker exec m7a-{name} python main.py divergent` |
| "货币战争" | `docker exec m7a-{name} python main.py currencywars` |
| "打混沌回忆" | `docker exec m7a-{name} python main.py forgottenhall` |
| "打虚构叙事" | `docker exec m7a-{name} python main.py purefiction` |
| "打末日幻影" | `docker exec m7a-{name} python main.py apocalyptic` |
| "兑换码发了没" | `docker exec m7a-{name} python main.py redemption` |

完整的触发词表见 [SKILL.md](skills/m7a/SKILL.md)。所有 AI 代理共享同一份 SKILL.md，无需分别维护。

---

## 配置说明

最小 `config.yaml` 约 50 行，放在 `m7a-data/accounts/{name}/` 下。核心配置项：

| 配置 | 说明 | 推荐值 |
|---|---|---|
| `cloud_game_enable` | 是否启用云游戏模式 | `true` |
| `browser_headless_enable` | 是否无头运行 | `true`（首次登录后） |
| `after_finish` | 任务完成后行为 | `Loop`（持续循环） |
| `daily_enable` | 每日实训 | `true` |
| `notify_type` | 通知类型 (`tg`) | 按需配置 |
| `scheduled_tasks` | 定时任务 | cron 表达式 |

完整配置参考 `m7a-data/template/config.yaml`，全部选项见 [官方示例配置](https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml)。

---

## 首次登录

首次登录无需配置任何通知推送，全程在 AI 代理聊天中完成。

1. 容器以 **headless 模式**启动，不弹任何窗口
2. M7A 检测到未登录状态，自动在云游戏页面生成 QR 码
3. QR 码截图自动保存到 `m7a-data/accounts/{name}/logs/qrcode_login.png`
4. AI 代理检测到该文件后，直接将二维码图片发送给你
5. 你用手机游戏客户端扫描 QR 码完成登录
6. 扫码成功后，容器继续 headless 运行，所有任务在后台静默执行

> QR 码有效期内未扫码？M7A 会自动刷新过期二维码，重新生成到 `qrcode_login.png`。

---

## 常见问题

### Docker 未安装或版本过低

```bash
docker --version                    # 检查版本
docker-compose version              # 确认 Compose V2
```

Docker Engine 需要 >= 20.10，Compose 需要 V2。参考 [Docker 官方安装文档](https://docs.docker.com/engine/install/)。

### 端口冲突

如果 9222 已被占用，修改 `docker-compose.yml` 中 `ports` 映射为其他值：

```yaml
ports:
  - "9222:9222"   # 改为 "9333:9222"
```

### 容器内存不足

默认限制 2GB。如果任务中途浏览器崩溃，增大 `mem_limit`：

```yaml
mem_limit: 3g
```

同时确保 `shm_size: 1g` 已设置（浏览器共享内存）。

### 配置错误导致容器退出

```bash
docker logs m7a-{name}    # 查看启动日志
```

常见原因：YAML 缩进错误、`tg_bot_token` 无效、文件路径不匹配。

### QR 码未生成

登录不需要配置通知推送，QR 码会直接保存到文件。如果未收到二维码：

- 检查文件是否存在：`ls -la m7a-data/accounts/{name}/logs/qrcode_login.png`
- 查看容器日志：`docker logs m7a-{name}` — 确认容器已正常启动并进入登录流程
- 确认 `config.yaml` 中 `cloud_game_enable: true` 和 `browser_headless_enable: true` 已设置
- 等待几秒后重新检查文件，M7A 可能需要时间加载云游戏页面
- 如果二维码过期，M7A 会自动刷新并重新保存，稍后重试即可

---

## 项目结构

```
m7a-skill/
├── skills/m7a/SKILL.md              # 通用 Skill 定义（适配所有 AI 代理）
├── docker-compose.yml               # Docker 编排配置
├── install.sh                       # 一键安装脚本
├── m7a-data/
│   ├── template/config.yaml         # 最小配置模板
│   └── accounts/                    # 各账号配置目录（按需创建）
├── LICENSE                          # MIT 许可证
└── README.md                        # 本文件
```

---

## 参考

- [March7thAssistant 项目主页](https://github.com/moesnow/March7thAssistant)
- [配置完整示例](https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml)
- [Skill 定义详情](skills/m7a/SKILL.md)
- [GitHub 仓库](https://github.com/Jerry-zhuang/m7a-skill)

---

## 开源

本项目基于 MIT 许可证开源。欢迎提交 Issue 和 Pull Request：

- **GitHub**: https://github.com/Jerry-zhuang/m7a-skill
- **一键安装**: `bash <(curl -fsSL https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/install.sh)`
- **OpenClaw**: `openclaw skills add https://github.com/Jerry-zhuang/m7a-skill`
- **Hermes**: `hermes skills install https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/skills/m7a/SKILL.md`
