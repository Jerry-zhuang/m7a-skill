---
name: m7a
description: 三月七小助手 (March7thAssistant) — 崩坏：星穹铁道 Docker 多账号自动化部署。支持日常实训、清体力、奖励领取、模拟宇宙、锄大地等全部功能。通过自然语言或斜杠命令触发任务执行和账号管理。m7a, 三月七, 星铁, star rail, daily, 清体力, 日常, 宇宙, 锄大地
homepage: https://github.com/moesnow/March7thAssistant
version: 1.0.0
author: m7a-skill
metadata:
  openclaw:
    category: gaming
    emoji: 🎮
---

<role>
M7A Docker 部署管理器
</role>

Docker 部署指令
- docker pull ghcr.io/moesnow/march7thassistant:latest
- docker-compose up -d
- 环境变量说明：容器启动时通过环境变量注入账号配置、端口、日志级别等，可在 m7a-data 目录下维护模板配置，具体变量以镜像文档为准。

账号管理指令
- 添加账号：将账号配置放置于 m7a-data/accounts/{account-name}/，并提供 config.yaml 配置模板；目录创建后通过 docker-compose up -d 启动。
- 列出账号：docker-compose ps
- 删除账号：docker-compose down m7a-{account-name}，再删除 m7a-data/accounts/{account-name} 目录
- 命名规则：小写字母+数字+连字符，2-30字符
- 端口分配：从 9222 开始自增分配端口
- 首次登录：容器全程 headless 运行，M7A 检测到未登录后自动生成 QR 码截图并保存到 logs/qrcode_login.png
- 首次登录流程：
  1. 启动容器（headless 模式）
  2. 等待 M7A 检测到未登录状态 → 自动生成 QR 码
  3. QR 码截图保存在: `m7a-data/accounts/{name}/logs/qrcode_login.png`
  4. 使用 `background_output` 或 Read 工具读取该图片文件
  5. 将 QR 码图片展示给用户扫码
  6. 扫码完成后，容器继续 headless 执行任务
  - 注意：无需配置通知推送，无需切换到非 headless 模式

中英文自然语言到 M7A CLI 命令映射表
| 自然语言 | CLI 命令 |
|---|---|
| 日常/每日/实训/daily | python main.py daily |
| 体力/清体力/power | python main.py power |
| 全部/完整运行/main | python main.py |
| 宇宙/模拟宇宙/universe | python main.py universe |
| 锄大地/fight | python main.py fight |
| 差分/divergent | python main.py divergent |
| 货币战争/currencywars | python main.py currencywars |
| 混沌回忆/forgottenhall | python main.py forgottenhall |
| 虚构叙事/purefiction | python main.py purefiction |
| 末日幻影/apocalyptic | python main.py apocalyptic |
| 兑换码/redemption | python main.py redemption |
| 奖励/reward | python main.py daily（包含在每日实训中） |
| 更新游戏/game_update | python main.py game_update |
- CLI 调用示例：通过 docker exec m7a-{name} python main.py <task> 触发任务
- 备注：所有任务均通过容器内的 python main.py 派发

配置管理
- 修改 m7a-data/accounts/{name}/config.yaml，使用最小模板+引用链接，确保能被容器读取并映射到对应账号
- 核心配置包括：账号凭证、任务参数、日志级别、调度策略等

调度指令
- M7A 原生 scheduled_tasks 功能，支持 after_finish: Loop 的循环执行
- 可以在 config.yaml 中配置每日或定时任务，容器内的任务调度将自动触发

监控与日志指令
- docker logs <container>：查看日志输出
- docker-compose ps：查看当前运行状态
- 其他监控：容器资源使用、日志级别等

故障排查指南
- 容器启动失败：检查镜像版本、环境变量、挂载路径是否正确
- QR 码未生成：检查 `m7a-data/accounts/{name}/logs/qrcode_login.png` 是否存在；用 `docker logs m7a-{name}` 查看容器是否已启动并进入登录流程
- 二维码过期：M7A 会自动刷新过期二维码并重新保存到 `qrcode_login.png`，重新读取即可
- 任务执行失败：查看日志、手动触发 python main.py <task> 进行重试
- 浏览器崩溃：确保 shm_size 设置为 1g，在浏览器相关任务中启用共享内存

### 交互式配置管理

#### 配置类别总览
| 类别 | 说明 |
|------|------|
| 副本刷取 | 修改体力刷取的副本类型和具体路径 |
| 功能开关 | 启用/禁用各项周常和任务 |
| 定时调度 | 配置 scheduled_tasks 定时执行 |
| 通知设置 | 消息推送渠道配置 |

#### 副本配置（用户最常用）
当用户说"改副本"或"换刷XXX"时：

**步骤1：读取当前配置**
```
Read("m7a-data/accounts/{name}/config.yaml")
```
提取 `instance_type`、`instance_names`、`power_plan` 等字段展示给用户。

**步骤2：展示可用选项**
列出所有副本类型供用户选择：

副本类型：
- 拟造花萼（金）：回忆之蕾（经验书）/ 藏珍之蕾（遗器经验）/ 毁灭之蕾（光锥经验）
- 拟造花萼（赤）：收容舱段 / 支援舱段 / 边缘通路 / 铆钉镇 / 机械聚落 / 大矿区
- 凝滞虚影：城郊雪原 / 鳞渊境 / 丹鼎司 / 「白日梦」酒店-梦境 / 绥园 / 克劳克影视乐园
- 侵蚀隧洞（遗器）：睿治之径 / 霜风之径 / 迅拳之径 / 漂泊之径 / 圣颂之径 / 野焰之径
- 饰品提取（位面饰品）：永恒笑剧 / 苍穹 / 匹诺康尼 / 繁星 / 龙骨 / 太空 / 仙舟 等
- 历战余响：毁灭的开端

**步骤3：确定具体副本路径**
用户选定类型后，列出该类型下所有可选的副本名。

**步骤4：更新配置**
```
Edit("m7a-data/accounts/{name}/config.yaml")
```
修改 `instance_type` 和对应的 `instance_names.{type}` 字段。

**步骤5：重启容器使生效**
```
docker-compose restart m7a-{name}
```

#### 开关配置
当用户说"打开周常"、"关闭锄大地"等：

| 用户说 | 配置键 | 值 |
|--------|--------|-----|
| "打开/关闭周常" | 逐个设置各周常 enable | true/false |
| "刷历战余响" | echo_of_war_enable | true |
| "打差分宇宙" | weekly_divergent_enable | true |
| "打货币战争" | currencywars_enable | true |
| "打混沌回忆" | forgottenhall_enable | true |
| "打虚构叙事" | purefiction_enable | true |
| "打末日幻影" | apocalyptic_enable | true |
| "自动分解遗器" | break_down_level_four_relicset | true |
| "使用燃料" | use_fuel | true |
| "使用后备开拓力" | use_reserved_trailblaze_power | true |
| "领取奖励" | 各 reward_* 字段 | true/false |

#### 定时调度配置
当用户说"每天6点执行日常"、"定时跑"等：
```
# 在 config.yaml 中配置 scheduled_tasks:
scheduled_tasks:
  - name: "每日实训"
    trigger_type: cron
    cron: "0 6 * * *"
    tasks: [daily]
```

展示 cron 格式说明或提供常见时间选项：
- 每天6点 → `0 6 * * *`
- 每天12点 → `0 12 * * *`  
- 每天18点 → `0 18 * * *`
- 每4小时 → `0 */4 * * *`
- 体力清空后自动 → `after_finish: Loop`

#### 完整流程示例
用户说："我想换刷睿治之径"
1. 代理读取 `m7a-data/accounts/main/config.yaml`
2. 展示当前副本配置："当前刷的是拟造花萼（金），可选类型有..."
3. 用户说："改侵蚀隧洞"
4. 代理展示侵蚀隧洞的所有可选路径（睿治之径、霜风之径、迅拳之径等）
5. 用户说："睿治之径"
6. 代理更新 config.yaml 中 `instance_type: 侵蚀隧洞` 和 `instance_names.侵蚀隧洞: 睿治之径`
7. 代理询问是否需要立即重启容器，如确认则执行 `docker-compose restart m7a-main`

---

后记
