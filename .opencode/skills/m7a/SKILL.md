---
name: m7a
description: 三月七小助手 (March7thAssistant) — 崩坏：星穹铁道 Docker 多账号自动化部署。支持日常实训、清体力、奖励领取、模拟宇宙、锄大地等全部功能。通过自然语言或斜杠命令触发任务执行和账号管理。m7a, 三月七, 星铁, star rail, daily, 清体力, 日常, 宇宙, 锄大地
---

<role>
M7A Docker 部署管理器
</role>

Docker 部署指令
- docker pull ghcr.io/moesnow/march7thassistant:latest
- docker compose up -d
- 环境变量说明：容器启动时通过环境变量注入账号配置、端口、日志级别等，可在 m7a-data 目录下维护模板配置，具体变量以镜像文档为准。

账号管理指令
- 添加账号：将账号配置放置于 m7a-data/accounts/{account-name}/，并提供 config.yaml 配置模板；目录创建后通过 docker compose up -d 启动。
- 列出账号：docker compose ps
- 删除账号：docker compose down m7a-{account-name}，再删除 m7a-data/accounts/{account-name} 目录
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
- docker compose ps：查看当前运行状态
- 其他监控：容器资源使用、日志级别等

故障排查指南
- 容器启动失败：检查镜像版本、环境变量、挂载路径是否正确
- QR 码未生成：检查 `m7a-data/accounts/{name}/logs/qrcode_login.png` 是否存在；用 `docker logs m7a-{name}` 查看容器是否已启动并进入登录流程
- 二维码过期：M7A 会自动刷新过期二维码并重新保存到 `qrcode_login.png`，重新读取即可
- 任务执行失败：查看日志、手动触发 python main.py <task> 进行重试
- 浏览器崩溃：确保 shm_size 设置为 1g，在浏览器相关任务中启用共享内存

后记
- 这份 SKILL.md 作为 M7A 的能力描述文件，用于自然语言触发 Docker 多账号部署与任务调度。所有操作均在容器内部执行，账号数据存储在 m7a-data 子目录中。
