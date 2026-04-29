# M7A Skill - Docker 多账号部署自动化

## TL;DR

> **目标**: 创建 opencode skill 文件，使 opencode 代理能够通过自然语言指令管理 March7thAssistant 的 Docker 多账号部署，实现崩坏：星穹铁道的全自动日常任务执行。
> 
> **交付物**:
> - `.opencode/skills/m7a/SKILL.md` — 核心 skill 定义文件
> - `docker-compose.yml` — 多账号 Docker 编排模板
> - `m7a-data/template/config.yaml` — 最小可运行配置模板
> - `.gitignore` — 项目忽略规则
> - `README.md` — 使用说明文档
> 
> **预估工作量**: Medium
> **并行执行**: YES - 2 waves
> **关键路径**: Task 1 → Task 3 → Task 5 → F1-F4

---

## Context

### Original Request
基于 March7thAssistant (moesnow/March7thAssistant) 项目，开发一个 opencode SKILL，采用 Docker 部署方式，实现崩坏：星穹铁道的游玩，例如每日实训的完成。

### Interview Summary
**Key Discussions**:
- **Skill 类型**: opencode skill 文件，直接使用项目官方 Docker 镜像
- **运行模式**: 云游戏浏览器模式 (Selenium headless Chrome)
- **功能范围**: M7A 全部功能（daily, power, reward, universe, fight 等）
- **配置管理**: 挂载 config.yaml（每账号独立配置）
- **通知推送**: 继承 M7A 原生通知（onepush/matrix）
- **触发方式**: 自然语言触发，映射到 M7A CLI 任务
- **部署方式**: 全自动（拉镜像、创建 compose、启动容器）
- **登录方式**: 通知推送二维码（M7A 原生支持）
- **多账号**: 多容器模式（每账号一个容器）
- **任务调度**: 定时+手动（after_finish: Loop + scheduled_tasks）
- **Skill 位置**: 项目级 (.opencode/skills/)

**Research Findings**:
- M7A 已有完整 Docker 支持：Dockerfile, docker-compose.yml, entrypoint.sh
- 官方镜像: `ghcr.io/moesnow/march7thassistant:latest`
- Docker 默认启用云游戏+无头浏览器模式
- 配置支持环境变量覆盖（MARCH7TH_* 前缀）
- 所有任务通过 `python main.py <task>` CLI 派发
- 两个 git submodule：Auto_Simulated_Universe, Fhoe-Rail
- 浏览器 Profile 通过 Volume 持久化
- docker-compose 需要 `shm_size: 1g`
- 首次登录需二维码扫描（通过通知推送）

### Metis Review
**Identified Gaps (addressed)**:
- **QR 登录流程**: 在 headless Docker 中，M7A 支持 `browser_headless_restart_on_not_logged_in` 但无显示器。需要在 skill 中明确首次登录流程：临时非无头模式 + 通知推送二维码。
- **端口冲突**: 多容器场景下 `browser_debug_port` 需要唯一分配（从 9222 递增）。
- **Config 规模**: config.example.yaml 500+ 行，skill 中只嵌入最小模板 + 引用链接。
- **容器资源**: Chrome 内存需求高，多容器需要 `mem_limit`。
- **时区**: 配置 `TZ` 环境变量确保 scheduled_tasks 时间正确。
- **账号命名**: 限制小写字母+数字+连字符，最长 30 字。
- **范围膨胀风险**: 明确排除通知配置向导、监控仪表板、自动更新、备份恢复等。
- **镜像版本**: 使用 `latest` 但文档说明风险，提供版本锁定选项。

---

## Work Objectives

### Core Objective
创建一个 opencode skill 文件，让用户通过自然语言（如"执行日常"、"清体力"）即可管理 March7thAssistant Docker 多账号部署，实现星穹铁道自动化任务的全生命周期管理。

### Concrete Deliverables
- `.opencode/skills/m7a/SKILL.md` — skill 定义文件（YAML frontmatter + 指令内容）
- `docker-compose.yml` — 多账号 Docker 编排模板（带注释和端口映射说明）
- `m7a-data/template/config.yaml` — 最小可运行配置模板（不含 500 行全量配置）
- `.gitignore` — 忽略 logs/、browser profile 等运行时数据
- `README.md` — 项目使用说明

### Definition of Done
- [ ] `ls .opencode/skills/m7a/SKILL.md` 存在且非空
- [ ] SKILL.md frontmatter 通过 YAML 解析验证
- [ ] `name: m7a` 与目录名 `m7a` 一致
- [ ] description 包含中英文触发关键词
- [ ] docker-compose.yml 是有效 YAML
- [ ] docker-compose.yml 包含 `shm_size: 1g`
- [ ] docker-compose.yml 使用官方镜像 `ghcr.io/moesnow/march7thassistant`
- [ ] config 模板小于 80 行（最小可运行配置，非全量配置）
- [ ] 所有文件不超出 `.opencode/skills/m7a/` 和项目根目录

### Must Have
- 自然语言到 M7A CLI 任务的映射（daily, power, reward, universe, fight 等）
- 多账号管理（添加、列出、删除账号对应的 Docker 容器）
- Docker 全自动部署指令（拉镜像、创建 compose、启动容器）
- 最小 config.yaml 生成模板（云游戏+无头+通知+调度）
- 首次登录（QR 码）流程文档
- 定时执行配置（scheduled_tasks）

### Must NOT Have (Guardrails)
- ❌ 不修改 M7A 源码或构建自定义 Docker 镜像
- ❌ 不创建 Python/Shell 辅助脚本（skill 是指令，不是代码）
- ❌ 不嵌入完整的 500 行 config.example.yaml
- ❌ 不实现通知配置向导（仅文档说明配置键）
- ❌ 不实现监控仪表板或健康检查 UI
- ❌ 不实现 Docker 镜像自动更新机制
- ❌ 不实现备份/恢复工具
- ❌ 不支持 Kubernetes/Docker Swarm 多主机部署
- ❌ 不包含游戏策略优化（阵容、遗器选择等）
- ❌ 不实现 VNC/Web 端口登录流程（使用通知推送 QR 码）

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (纯配置文件项目，无测试框架)
- **Automated tests**: None
- **Framework**: N/A
- **Agent-Executed QA**: 所有 QA 通过文件检查和 YAML 验证执行

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Skill 文件**: Bash (文件检查, YAML 解析, grep 关键词)
- **Docker 配置**: Bash (yq/yaml 验证, 结构检查)
- **Config 模板**: Bash (YAML 解析, 关键键值验证)

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - foundation + core):
├── Task 1: Project scaffolding + .gitignore [quick]
├── Task 2: Minimal config template [quick]
├── Task 3: SKILL.md core - frontmatter, role, trigger mapping, task dispatch [deep]
└── Task 4: Docker compose template [unspecified-high]

Wave 2 (After Wave 1 - integration docs):
└── Task 5: README.md - project usage documentation [writing]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── F1: Plan compliance audit (oracle)
├── F2: File quality review (unspecified-high)
├── F3: Real QA - file validation scenarios (unspecified-high)
└── F4: Scope fidelity check (deep)
→ Present results → Get explicit user okay

Critical Path: Task 2 → Task 4 → Task 5 → F1-F4 → user okay
Parallel Speedup: ~50% faster than sequential
Max Concurrent: 4 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks | Wave |
|------|-----------|--------|------|
| 1    | - | 5 | 1 |
| 2    | - | 4, 5 | 1 |
| 3    | - | 5 | 1 |
| 4    | 2 (config 变量和挂载路径) | 5 | 1 |
| 5    | 1, 2, 3, 4 | F1-F4 | 2 |
| F1-F4 | 1-5 | user | FINAL |

### Agent Dispatch Summary

- **Wave 1**: **4** - T1 → `quick`, T2 → `quick`, T3 → `deep`, T4 → `unspecified-high`
- **Wave 2**: **1** - T5 → `writing`
- **FINAL**: **4** - F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Project Scaffolding + .gitignore

  **What to do**:
  - 创建项目目录结构: `mkdir -p .opencode/skills/m7a m7a-data/template m7a-data/accounts logs`
  - 创建 `.gitignore` 文件，忽略: `m7a-data/accounts/*/logs/`, `m7a-data/accounts/*/browser-profile/`, `m7a-data/accounts/*/config.yaml`, `logs/`, `*.log`, `__pycache__/`, `.DS_Store`
  - 创建 `m7a-data/.gitkeep` 和 `m7a-data/accounts/.gitkeep` 占位文件
  - 创建 `m7a-data/template/` 目录已包含 config 模板（Task 2 负责）

  **Must NOT do**:
  - 不创建 Python 脚本或 Shell 脚本
  - 不创建 `.env` 文件（敏感信息不应入库）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 简单的目录创建和 .gitignore 文件编写
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `playwright`: 不需要浏览器交互
    - `git-master`: 不需要 git 高级操作

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - M7A 官方仓库 `.gitignore` — 了解 M7A 项目忽略了哪些文件
  - 典型 Python+Docker 项目 .gitignore 模式

  **API/Type References**:
  - N/A

  **Test References**:
  - N/A

  **External References**:
  - GitHub .gitignore 模板最佳实践

  **WHY Each Reference Matters**:
  - gitignore 需要排除 M7A 运行时生成的文件（logs、browser profile、user config），同时保留模板文件

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Directory structure created correctly
    Tool: Bash
    Preconditions: Clean project directory
    Steps:
      1. ls -la .opencode/skills/m7a/ — verify directory exists
      2. ls -la m7a-data/template/ — verify directory exists
      3. ls -la m7a-data/accounts/ — verify directory exists
      4. test -f .gitignore && echo "OK" — verify .gitignore exists
    Expected Result: All directories exist, .gitignore present
    Failure Indicators: Missing directory or file
    Evidence: .sisyphus/evidence/task-1-dir-structure.txt

  Scenario: .gitignore covers runtime data
    Tool: Bash
    Preconditions: .gitignore file exists
    Steps:
      1. grep -c 'logs' .gitignore — should be >= 1
      2. grep -c 'browser-profile' .gitignore — should be >= 1
      3. grep -c 'config.yaml' .gitignore — should be >= 1 (user configs, not templates)
    Expected Result: All runtime data patterns are covered
    Failure Indicators: Missing pattern means accidental commit of runtime data
    Evidence: .sisyphus/evidence/task-1-gitignore-check.txt
  ```

  **Commit**: YES (groups with Task 2)
  - Message: `feat: init m7a-skill project scaffolding`
  - Files: `.gitignore`, `.gitkeep` files
  - Pre-commit: `ls .gitignore && ls .opencode/skills/m7a/`

- [x] 2. Minimal Config Template

  **What to do**:
  - 创建 `m7a-data/template/config.yaml` — 最小可运行配置
  - 仅包含核心设置段:
    - `locales: zh_CN`
    - `ui_language: auto`
    - `log_level: INFO`
    - `log_overlay_enable: false` (Docker 无需浮窗)
    - `check_update: false` (Docker 镜像管理更新)
    - `pause_after_success: false`
    - `exit_after_failure: true`
    - `after_finish: Loop` (持续运行模式)
    - `cloud_game_enable: true`
    - `browser_type: integrated`
    - `browser_headless_enable: true`
    - `browser_persistent_enable: true`
    - `browser_download_use_mirror: true`
    - `cloud_game_fullscreen_enable: true`
    - 游戏窗口配置: `game_title_name`, `game_process_name`
    - 奖励领取配置: `reward_enable: true` 及各子项
    - 日常任务配置: `daily_enable: true`
    - 分解配置: `break_down_level_four_relicset: false`
    - 通知推送配置: 注释说明 onepush 配置方式，引用官方文档
    - 定时配置: `scheduled_tasks` 注释说明
  - 在文件顶部添加注释: `# March7thAssistant 最小运行配置 — 完整选项见 https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml`
  - 总行数控制在 80 行以内

  **Must NOT do**:
  - 不嵌入完整的 500+ 行 config.example.yaml
  - 不硬编码通知密钥或敏感信息
  - 不包含本地游戏路径配置（Docker 模式不需要）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 编写约 60-80 行 YAML 配置文件
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4)
  - **Blocks**: Task 4 (需要 config 变量名和挂载路径)
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml` — 官方完整配置，从中提取最小必需键
  - M7A Dockerfile 环境变量默认值 — `MARCH7TH_CLOUD_GAME_ENABLE=true`, `MARCH7TH_BROWSER_HEADLESS_ENABLE=true` 等

  **API/Type References**:
  - M7A `module/config/config.py` 的 `_ENV_OVERRIDE_MAP` — 了解哪些配置键支持环境变量覆盖

  **Test References**:
  - N/A

  **External References**:
  - M7A 官方配置文档: https://m7a.top

  **WHY Each Reference Matters**:
  - config.example.yaml 是唯一的权威配置源，模板必须从中提取键名和默认值
  - 环境变量覆盖映射决定哪些配置可以通过 Docker env var 设置

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Config template is valid YAML with required keys
    Tool: Bash
    Preconditions: m7a-data/template/config.yaml exists
    Steps:
      1. python3 -c "import yaml; yaml.safe_load(open('m7a-data/template/config.yaml'))" — 验证 YAML 语法
      2. grep -c 'cloud_game_enable' m7a-data/template/config.yaml — should be 1
      3. grep -c 'browser_headless_enable' m7a-data/template/config.yaml — should be 1
      4. grep -c 'after_finish' m7a-data/template/config.yaml — should be >= 1
      5. wc -l m7a-data/template/config.yaml — should be < 80
    Expected Result: Valid YAML, all required keys present, under 80 lines
    Failure Indicators: YAML parse error, missing key, over 80 lines
    Evidence: .sisyphus/evidence/task-2-config-valid.txt

  Scenario: Config template does NOT contain full 500-line example
    Tool: Bash
    Preconditions: m7a-data/template/config.yaml exists
    Steps:
      1. wc -l m7a-data/template/config.yaml — must be under 80
      2. grep -c 'echo_of_war' m7a-data/template/config.yaml — should be 0 (非核心可选项不应出现)
      3. grep -c 'scheduled_tasks' m7a-data/template/config.yaml — should be >= 1 (注释形式存在即可)
    Expected Result: Minimal config, non-essential keys absent, reference to full example present
    Failure Indicators: Over 80 lines or containing obscure optional keys
    Evidence: .sisyphus/evidence/task-2-config-minimal.txt
  ```

  **Commit**: YES (groups with Task 1)
  - Message: `feat: add minimal M7A config template`
  - Files: `m7a-data/template/config.yaml`
  - Pre-commit: `python3 -c "import yaml; yaml.safe_load(open('m7a-data/template/config.yaml'))"`

- [x] 3. SKILL.md Core — Skill Definition File

  **What to do**:
  - 创建 `.opencode/skills/m7a/SKILL.md` — 核心 skill 定义文件
  - YAML frontmatter:
    ```yaml
    ---
    name: m7a
    description: 三月七小助手 (March7thAssistant) — 崩坏：星穹铁道 Docker 多账号自动化部署。支持日常实训、清体力、奖励领取、模拟宇宙、锄大地等全部功能。通过自然语言或斜杠命令触发任务执行和账号管理。m7a, 三月七, 星铁, star rail, daily, 清体力, 日常, 宇宙, 锄大地
    ---
    ```
  - `<role>` 段: 定义代理为 M7A Docker 部署管理器，负责容器生命周期和任务调度
  - **Docker 部署指令段**:
    - 拉取官方镜像: `docker pull ghcr.io/moesnow/march7thassistant:latest`
    - 检查镜像版本和更新
    - 必需 Docker 环境变量列表和说明
  - **账号管理指令段**:
    - 添加账号: 创建 `m7a-data/accounts/{account-name}/` 目录 → 写入 config.yaml → 添加服务到 docker-compose.yml → `docker compose up -d m7a-{account-name}`
    - 列出账号: `docker compose ps --format "table {{.Name}}\t{{.Status}}"`
    - 删除账号: `docker compose down m7a-{account-name}` → 删除目录 → 从 compose 移除服务定义
    - 账号命名规则: 小写字母+数字+连字符，2-30字符，不允许下划线
    - 端口分配: browser_debug_port 从 9222 递增（9222, 9223, 9224...）
    - 首次登录流程: 临时设置 `browser_headless_enable: false` → 通知推送二维码 → 用户扫码 → 恢复 headless
  - **任务触发映射段**:
    - 中英文自然语言到 M7A CLI 命令的映射表:
      | 自然语言 (中/英) | CLI 命令 |
      |---|---|
      | 日常/每日/实训/daily | `python main.py daily` |
      | 体力/清体力/power | `python main.py power` |
      | 全部/完整运行/main | `python main.py` |
      | 奖励/reward | 通过 daily 包含 |
      | 宇宙/模拟宇宙/universe | `python main.py universe` |
      | 锄大地/fight | `python main.py fight` |
      | 差分/divergent | `python main.py divergent` |
      | 货币战争/currencywars | `python main.py currencywars` |
      | 混沌回忆/forgottenhall | `python main.py forgottenhall` |
      | 虚构叙事/purefiction | `python main.py purefiction` |
      | 末日幻影/apocalyptic | `python main.py apocalyptic` |
      | 兑换码/redemption | `python main.py redemption` |
      | 更新游戏/game_update | `python main.py game_update` |
    - 任务执行: `docker exec m7a-{account-name} python main.py {task}`
    - 指定账号: `docker exec m7a-{account-name} python main.py daily`
    - 所有账号: 逐个 `docker exec` 或 `docker compose exec`
  - **配置管理指令段**:
    - 编辑账号配置: `m7a-data/accounts/{account-name}/config.yaml`
    - 使用最小模板 + 完整参考链接的方式
    - 不实现配置向导，仅指导用户编辑配置文件
  - **调度指令段**:
    - 使用 M7A 原生 `scheduled_tasks` 配置（非外部 cron）
    - 在 config.yaml 中配置定时任务
    - 配合 `after_finish: Loop` 实现持续运行
  - **监控与日志段**:
    - 查看日志: `docker logs -f m7a-{account-name}`
    - 查看状态: `docker compose ps`
    - 重启容器: `docker compose restart m7a-{account-name}`
  - **故障排查段**:
    - 容器无法启动: 检查 shm_size、端口冲突、config 语法
    - 二维码未推送: 检查通知配置、检查非无头模式
    - 任务执行失败: 检查日志 `docker logs`
    - 浏览器崩溃: 检查内存限制、增加 mem_limit

  **Must NOT do**:
  - 不包含 Python/Shell 可执行脚本
  - 不嵌入完整 500 行配置
  - 不实现通知配置向导
  - 不实现健康检查仪表板
  - 不实现自动更新机制
  - 不在 role 中让代理直接修改游戏逻辑或策略

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 核心交付物，需要深入理解 M7A 架构和 skill 格式，确保映射完整和指令精确
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4)
  - **Blocks**: Task 5
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `.opencode/skills/` 目录下现有 skill 文件 — 学习 opencode skill 格式（如果存在）
  - M7A `utils/tasks.py` `AVAILABLE_TASKS` — 所有可用 CLI 命令的权威列表

  **API/Type References**:
  - opencode SKILL.md 格式规范 — YAML frontmatter 必需字段 (`name`, `description`)、内容结构 (`<role>`, sections)
  - M7A `module/config/config.py` `_ENV_OVERRIDE_MAP` — 环境变量覆盖映射
  - M7A `module/game/cloud.py` — 云游戏控制器，理解 browser 参数和 headless 逻辑

  **Test References**:
  - N/A

  **External References**:
  - opencode Custom Skills 文档: https://www.mintlify.com/code-yeongyu/oh-my-opencode/advanced/custom-skills
  - M7A 官方教程: https://m7a.top
  - M7A Dockerfile: https://github.com/moesnow/March7thAssistant/blob/main/Dockerfile
  - M7A docker-compose.yml: https://github.com/moesnow/March7thAssistant/blob/main/docker-compose.yml

  **WHY Each Reference Matters**:
  - tasks.py 确保所有 CLI 命令映射准确，无遗漏
  - _ENV_OVERRIDE_MAP 确保 Docker 环境变量名称和转换逻辑正确
  - cloud.py 确保浏览器参数说明与实际代码一致
  - opencode skill 格式规范确保 SKILL.md 被正确识别和加载

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: SKILL.md frontmatter is valid and contains required fields
    Tool: Bash
    Preconditions: .opencode/skills/m7a/SKILL.md exists
    Steps:
      1. python3 -c "
      content = open('.opencode/skills/m7a/SKILL.md').read()
      parts = content.split('---')
      fm = __import__('yaml').safe_load(parts[1])
      assert fm['name'] == 'm7a', f'name mismatch: {fm[\"name\"]}'
      assert 'description' in fm, 'missing description'
      desc = fm['description']
      assert '三月七' in desc or 'm7a' in desc, 'missing trigger keywords'
      assert '日常' in desc or 'daily' in desc, 'missing task keywords'
      print('Frontmatter valid')
      "
      2. test "$(dirname .opencode/skills/m7a/SKILL.md | xargs basename)" = "m7a" — 验证目录名与 name 字段匹配
    Expected Result: Frontmatter validates, name='m7a', description contains trigger keywords
    Failure Indicators: YAML parse error, name mismatch, missing keywords
    Evidence: .sisyphus/evidence/task-3-frontmatter.txt

  Scenario: SKILL.md contains all required instruction sections
    Tool: Bash
    Preconditions: .opencode/skills/m7a/SKILL.md exists
    Steps:
      1. grep -c 'role' .opencode/skills/m7a/SKILL.md — should be >= 1
      2. grep -c 'docker' .opencode/skills/m7a/SKILL.md — should be >= 3
      3. grep -c 'docker exec' .opencode/skills/m7a/SKILL.md — should be >= 1
      4. grep -c '账号\|account' .opencode/skills/m7a/SKILL.md — should be >= 2
      5. grep -c 'main.py' .opencode/skills/m7a/SKILL.md — should be >= 5
      6. grep -c 'scheduled_tasks\|定时\|调度' .opencode/skills/m7a/SKILL.md — should be >= 1
      7. grep -c 'ghcr.io/moesnow/march7thassistant' .opencode/skills/m7a/SKILL.md — should be >= 1
    Expected Result: All required sections present with relevant keywords
    Failure Indicators: Missing section means incomplete skill definition
    Evidence: .sisyphus/evidence/task-3-content-check.txt

  Scenario: SKILL.md does NOT contain forbidden content
    Tool: Bash
    Preconditions: .opencode/skills/m7a/SKILL.md exists
    Steps:
      1. wc -c .opencode/skills/m7a/SKILL.md — should be < 15000 (不是小说)
      2. grep -c 'import \|^#!/bin/bash\|^#!/usr/bin/env python' .opencode/skills/m7a/SKILL.md — should be 0 (无脚本)
      3. Verify SKILL.md does not contain entire config.example.yaml embedded
      Expected Result: File is concise, contains no executable code, no bloated config
    Failure Indicators: Over 15KB, contains scripts, or embeds full config
    Evidence: .sisyphus/evidence/task-3-slop-check.txt
  ```

  **Commit**: YES
  - Message: `feat: add M7A skill definition for opencode`
  - Files: `.opencode/skills/m7a/SKILL.md`
  - Pre-commit: `python3 -c "import yaml; content=open('.opencode/skills/m7a/SKILL.md').read(); yaml.safe_load(content.split('---')[1])"`

- [x] 4. Docker Compose Multi-Account Template

  **What to do**:
  - 创建 `docker-compose.yml` — 多账号编排模板
  - 不包含任何具体账号服务定义（由 skill 动态添加）
  - 包含注释说明如何添加新账号服务
  - 服务模板要点:
    - 服务命名: `m7a-{account-name}`
    - 镜像: `ghcr.io/moesnow/march7thassistant:latest`
    - `shm_size: 1g` (Chrome 共享内存需求)
    - `restart: unless-stopped` (持续运行)
    - 环境变量:
      - `MARCH7TH_CLOUD_GAME_ENABLE=true`
      - `MARCH7TH_BROWSER_HEADLESS_ENABLE=true`
      - `MARCH7TH_DOCKER_STARTED=true`
      - `TZ=Asia/Shanghai`
    - Volume 挂载:
      - `./m7a-data/accounts/{account-name}/config.yaml:/m7a/config.yaml`
      - `./m7a-data/accounts/{account-name}/logs:/m7a/logs`
      - `./m7a-data/accounts/{account-name}/browser-profile:/m7a/3rdparty/WebBrowser/UserProfile`
    - 端口映射: `{debug_port}:9222` (每个账号唯一端口，从 9222 递增)
    - `mem_limit: 2g` (Chrome 内存限制)
  - 提供一个示例账号 `m7a-main` (注释状态) 作为参考
  - 不使用 compose `version:` 字段（兼容 Compose V2+）

  **Must NOT do**:
  - 不硬编码账号名或端口到活跃服务
  - 不使用 `version:` 字段（已废弃）
  - 不暴露不必要的端口（仅 debug 端口）
  - 不设置 `privileged: true` 或 `host` 网络模式

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Docker compose 模板需要精确的配置，错误的端口映射或 Volume 挂载会导致运行时失败
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (但需要参考 Task 2 的 config 路径约定)
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3)
  - **Blocks**: Task 5
  - **Blocked By**: Task 2 (需要 config 变量名和挂载路径)

  **References**:

  **Pattern References**:
  - M7A 官方 `docker-compose.yml` — https://github.com/moesnow/March7thAssistant/blob/main/docker-compose.yml — 学习 Volume 挂载路径和环境变量

  **API/Type References**:
  - M7A `Dockerfile` — 环境变量默认值、工作目录 `/m7a`
  - M7A `entrypoint.sh` — arm64 环境变量设置逻辑

  **Test References**:
  - N/A

  **External References**:
  - Docker Compose specification: https://docs.docker.com/compose/compose-file/
  - M7A Docker 运行文档: https://m7a.top

  **WHY Each Reference Matters**:
  - 官方 compose 是唯一的 Volume 路径和环境变量权威来源
  - Dockerfile 确认工作目录和必需环境变量
  - Compose 规范确保 yaml 格式正确

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: docker-compose.yml is valid YAML with required structure
    Tool: Bash
    Preconditions: docker-compose.yml exists
    Steps:
      1. python3 -c "import yaml; data=yaml.safe_load(open('docker-compose.yml')); assert 'services' in data, 'missing services key'; print('Valid compose')" — 验证 YAML 语法和顶层结构
      2. grep -c 'shm_size.*1g' docker-compose.yml — should be >= 1
      3. grep -c 'ghcr.io/moesnow/march7thassistant' docker-compose.yml — should be >= 1
      4. grep -c 'MARCH7TH_DOCKER_STARTED' docker-compose.yml — should be >= 1
      5. grep -c 'MARCH7TH_CLOUD_GAME_ENABLE' docker-compose.yml — should be >= 1
    Expected Result: Valid compose YAML with all required Docker settings
    Failure Indicators: YAML parse error or missing required key
    Evidence: .sisyphus/evidence/task-4-compose-valid.txt

  Scenario: docker-compose.yml does NOT contain security risks
    Tool: Bash
    Preconditions: docker-compose.yml exists
    Steps:
      1. grep -c 'privileged.*true' docker-compose.yml — should be 0
      2. grep -c 'network_mode.*host' docker-compose.yml — should be 0
      3. grep -c '^version:' docker-compose.yml — should be 0 (no deprecated version field)
    Expected Result: No privileged mode, no host networking, no deprecated version
    Failure Indicators: Security risk detected
    Evidence: .sisyphus/evidence/task-4-compose-security.txt
  ```

  **Commit**: YES
  - Message: `feat: add docker-compose multi-account template`
  - Files: `docker-compose.yml`
  - Pre-commit: `python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))"`

- [x] 5. README.md — Project Usage Documentation

  **What to do**:
  - 创建 `README.md` — 项目使用说明
  - 内容结构:
    - 项目标题和简介（M7A Skill for opencode — 三月七小助手 Docker 多账号部署）
    - 功能特性列表
    - 快速开始（前置条件 → 部署 → 配置 → 运行）
    - 多账号管理（添加/列出/删除账号）
    - 任务触发（自然语言 → M7A CLI 映射表）
    - 配置说明（最小配置 vs 完整配置链接）
    - 首次登录流程（二维码扫码说明）
    - 常见问题（Docker 未安装、端口冲突、容器内存不足、配置错误等）
    - 参考链接
  - 中文编写（M7A 目标用户主要为中文用户）
  - 简洁、实用、无冗余

  **Must NOT do**:
  - 不重复 SKILL.md 中已有的完整指令内容（README 是用户指南，不是复制 skill）
  - 不创建教程级别的逐步截图说明
  - 不包含敏感信息（API 密钥、账号密码）

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: 文档编写任务，需要清晰简洁的中文表达
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (sequential, needs all Wave 1 outputs)
  - **Blocks**: F1-F4
  - **Blocked By**: Tasks 1, 2, 3, 4 (需要引用所有交付物的实际内容)

  **References**:

  **Pattern References**:
  - M7A 官方 README.md — 风格和内容结构参考
  - 优秀 Docker 项目 README 模板

  **API/Type References**:
  - 所有 Task 1-4 的交付物 — README 引用实际文件名和路径

  **Test References**:
  - N/A

  **External References**:
  - M7A 官方教程: https://m7a.top

  **WHY Each Reference Matters**:
  - README 需要与实际项目结构和文件名精确对应

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: README exists and references all key files
    Tool: Bash
    Preconditions: README.md exists
    Steps:
      1. test -f README.md && echo "OK" — file exists
      2. grep -c 'SKILL.md' README.md — should be >= 1
      3. grep -c 'docker-compose.yml' README.md — should be >= 1
      4. grep -c 'config.yaml' README.md — should be >= 1
      5. grep -c 'm7a-data' README.md — should be >= 1
    Expected Result: README references all key project files
    Failure Indicators: Missing reference means incomplete documentation
    Evidence: .sisyphus/evidence/task-5-readme-check.txt

  Scenario: README contains essential sections
    Tool: Bash
    Preconditions: README.md exists
    Steps:
      1. grep -c '快速开始\|Quick Start' README.md — should be >= 1
      2. grep -c '多账号\|account' README.md — should be >= 1
      3. grep -c '配置\|config' README.md — should be >= 1
      4. grep -c '登录\|login\|二维码\|QR' README.md — should be >= 1
      5. grep -c '常见问题\|FAQ\|故障' README.md — should be >= 1
    Expected Result: README covers all essential topics
    Failure Indicators: Missing section means incomplete documentation
    Evidence: .sisyphus/evidence/task-5-readme-sections.txt
  ```

  **Commit**: YES
  - Message: `docs: add project README`
  - Files: `README.md`
  - Pre-commit: `test -f README.md`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, grep content). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **File Quality Review** — `unspecified-high`
  Review all created files for: invalid YAML syntax, missing required fields, inconsistent references (wrong paths, wrong image names, wrong port numbers), placeholder text left in, over-engineered sections (500-line config, notification wizard, monitoring dashboard), poor markdown formatting. Check SKILL.md frontmatter validates. Check docker-compose.yml parses as valid compose spec.
  Output: `YAML [N/N valid] | References [N/N consistent] | Placeholders [0 found] | Slop [0 found] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration: do SKILL.md instructions match docker-compose.yml service names? Do config variable names match between template and compose env vars? Do port numbers in compose match skill instructions? Test edge cases: account names with special characters, missing Docker, invalid config.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual file content. Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance: no Python/Shell scripts, no full 500-line config, no monitoring dashboard. Detect cross-task contamination. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **1**: `feat: init m7a-skill project scaffolding` - .gitignore
- **2**: `feat: add minimal M7A config template` - m7a-data/template/config.yaml
- **3**: `feat: add M7A skill definition for opencode` - .opencode/skills/m7a/SKILL.md
- **4**: `feat: add docker-compose multi-account template` - docker-compose.yml
- **5**: `docs: add project README` - README.md

---

## Success Criteria

### Verification Commands
```bash
test -f .opencode/skills/m7a/SKILL.md && echo "SKILL.md exists" || echo "MISSING"
test -f docker-compose.yml && echo "docker-compose.yml exists" || echo "MISSING"
test -f m7a-data/template/config.yaml && echo "config template exists" || echo "MISSING"
test -f .gitignore && echo ".gitignore exists" || echo "MISSING"
test -f README.md && echo "README exists" || echo "MISSING"
python3 -c "import yaml; content=open('.opencode/skills/m7a/SKILL.md').read(); fm=yaml.safe_load(content.split('---')[1]); assert fm['name']=='m7a', 'name mismatch'; print('Frontmatter valid')"
grep -c 'shm_size.*1g' docker-compose.yml  # Expected: >=1
grep -c 'ghcr.io/moesnow/march7thassistant' docker-compose.yml  # Expected: >=1
wc -l m7a-data/template/config.yaml  # Expected: < 80
```

### Final Checklist
- [x] All "Must Have" present
- [x] All "Must NOT Have" absent
- [x] SKILL.md frontmatter validates as YAML
- [x] docker-compose.yml parses as valid compose spec
- [x] Config template is minimal (< 80 lines)
- [x] No Python/Shell helper scripts created
- [x] No full config.example.yaml embedded