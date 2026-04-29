# M7A Skill — 三月七小助手 Docker 多账号自动部署

基于 [March7thAssistant](https://github.com/moesnow/March7thAssistant) 的 Docker 多账号部署方案，通过 opencode 自然语言触发任务执行和账号管理。每个游戏账号运行一个独立容器，互不干扰。

---

## 功能特性

- **多账号云游戏** — 每个账号独立容器，支持 N 个账号并行管理
- **全自动任务** — 日常实训、清体力、模拟宇宙、锄大地、混沌回忆等全自动执行
- **Docker 部署** — 一键拉取镜像，Compose 编排，快速启停
- **消息通知** — 支持 Telegram 等渠道推送任务结果和扫码登录
- **定时调度** — 内置 cron 定时任务 + `after_finish: Loop` 循环模式
- **自然语言触发** — 在 opencode 中用中文描述任务，自动映射为 CLI 命令

---

## 前置条件

- Docker Engine >= 20.10
- Docker Compose V2（`docker compose` 命令，非旧版 `docker-compose`）
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
docker compose up -d
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
docker compose up -d
```

账号命名规则：小写字母 + 数字 + 连字符，2-30 个字符。

### 列出账号

```bash
docker compose ps
```

### 删除账号

```bash
docker compose down m7a-{account-name}
rm -rf m7a-data/accounts/{account-name}
```

---

## 任务触发

在 opencode 中使用自然语言描述任务，系统会自动映射到容器内 CLI 命令并执行。

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

完整的触发词表见 [SKILL.md](.opencode/skills/m7a/SKILL.md)。

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

1. 启动容器后，系统会自动打开非 headless 浏览器
2. 浏览器显示崩坏：星穹铁道登录 QR 码
3. 如果配置了 Telegram 通知，二维码图片会推送到你的手机
4. 用手机游戏客户端扫描 QR 码完成登录
5. 登录成功后容器自动切换为 headless 模式，后续运行不再弹窗
6. 之后所有任务在后台静默执行

> 收不到 QR 码？检查 `tg_bot_token` 和 `tg_user_id` 是否配置正确。

---

## 常见问题

### Docker 未安装或版本过低

```bash
docker --version                    # 检查版本
docker compose version              # 确认 Compose V2
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

### QR 码未推送

- 确认 `notify_enable: true` 和 `notify_type: tg` 已配置
- 确认 `tg_bot_token` 和 `tg_user_id` 填写正确
- 首次启动时观察容器日志是否有推送相关输出：`docker logs m7a-{name}`
- 备选方案：通过 VNC 或直接查看容器浏览器界面扫码（需额外配置）

---

## 项目结构

```
m7a-skill/
├── .opencode/skills/m7a/SKILL.md   # Skill 定义（触发词、指令表）
├── docker-compose.yml               # Docker 编排配置
├── m7a-data/
│   ├── template/config.yaml         # 最小配置模板
│   └── accounts/                    # 各账号配置目录（按需创建）
└── README.md                        # 本文件
```

---

## 参考

- [March7thAssistant 项目主页](https://github.com/moesnow/March7thAssistant)
- [配置完整示例](https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml)
- [Skill 定义详情](.opencode/skills/m7a/SKILL.md)
