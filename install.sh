#!/usr/bin/env bash
# =============================================================================
# M7A Skill — 一键安装脚本（支持 Linux / macOS / Windows WSL）
# =============================================================================
# 用法:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/install.sh)
#
# 自动检测当前环境中的 AI 编码代理，将 skill 安装到正确位置。
# 支持 Linux、macOS、Windows (WSL/Git Bash/MSYS2)。
# Windows 用户也可使用 install.ps1（PowerShell）。
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/Jerry-zhuang/m7a-skill.git"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------------------------------------------------------------------------
# OS 检测
# ---------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    Darwin) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

OS="$(detect_os)"

# ---------------------------------------------------------------------------
# 路径工具：$HOME 在 Git Bash 下可能不是标准格式
# ---------------------------------------------------------------------------
home_dir() {
  case "$OS" in
    windows) echo "${USERPROFILE:-$HOME}" ;;
    *)       echo "$HOME" ;;
  esac
}

HOME_DIR="$(home_dir)"

# ---------------------------------------------------------------------------
# 安装 skill 到目标目录
# ---------------------------------------------------------------------------
install_skill() {
  local platform="$1"
  local target_dir="$2"
  local source_path="${PROJECT_DIR}/skills/m7a"

  mkdir -p "$(dirname "$target_dir")"

  if [ -L "$target_dir" ] || [ -d "$target_dir" ]; then
    log_info "${platform}: 已存在，跳过 (${target_dir})"
    return 0
  fi

  # Symlink 尝试，失败则降级为 copy
  if ln -sf "$source_path" "$target_dir" 2>/dev/null; then
    log_ok "${platform}: skill 已安装 → ${target_dir}"
  else
    cp -r "$source_path" "$target_dir"
    log_ok "${platform}: skill 已安装 (copy fallback) → ${target_dir}"
  fi
}

# ---------------------------------------------------------------------------
# 检测并安装各平台 AI 代理
# ---------------------------------------------------------------------------
install_openclaw() {
  local dir
  case "$OS" in
    windows) dir="${HOME_DIR}\\.openclaw\\skills\\m7a" ;;
    *)       dir="${OPENCLAW_SKILLS_DIR:-${HOME_DIR}/.openclaw/skills/m7a}" ;;
  esac
  if [ -n "${OPENCLAW_SKILLS_DIR:-}" ] || [ -d "$(dirname "$dir")" ]; then
    install_skill "OpenClaw (龙虾)" "$dir"
    return 0
  fi
  return 1
}

install_hermes() {
  local dir
  case "$OS" in
    windows) dir="${HOME_DIR}\\.hermes\\skills\\m7a" ;;
    *)       dir="${HERMES_SKILLS_DIR:-${HOME_DIR}/.hermes/skills/m7a}" ;;
  esac
  if [ -n "${HERMES_SKILLS_DIR:-}" ] || [ -d "$(dirname "$dir")" ]; then
    install_skill "Hermes (爱马仕)" "$dir"
    return 0
  fi
  return 1
}

install_opencode() {
  local dir="./.opencode/skills/m7a"
  if [ -d "./.opencode/skills" ]; then
    install_skill "opencode" "$dir"
    return 0
  fi
  return 1
}

install_claudecode() {
  local dir="${HOME_DIR}/.claude/skills/m7a"
  if [ -d "$(dirname "$dir")" ]; then
    install_skill "Claude Code" "$dir"
    return 0
  fi
  local project_dir="./.claude/skills/m7a"
  if [ -d "./.claude/skills" ]; then
    install_skill "Claude Code (project)" "$project_dir"
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# 前置检查
# ---------------------------------------------------------------------------
check_prerequisites() {
  log_info "系统: ${OS}"
  log_info "检查前置依赖..."

  local has_docker=false
  if command -v docker &>/dev/null; then
    log_ok "Docker $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
    has_docker=true
  else
    log_warn "Docker 未安装。M7A 需要 Docker Engine >= 20.10。"
  fi

  if docker compose version &>/dev/null; then
    log_ok "Docker Compose $(docker compose version 2>/dev/null | awk '{print $4}' | tr -d ',')"
  elif docker-compose --version &>/dev/null; then
    log_ok "Docker Compose (legacy) $(docker-compose --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
  else
    log_warn "Docker Compose V2 未安装。"
  fi

  echo ""
  if ! $has_docker; then
    log_warn "安装 Docker: https://docs.docker.com/engine/install/"
    echo ""
  fi
}

# ---------------------------------------------------------------------------
# 创建账号数据目录
# ---------------------------------------------------------------------------
create_data_dirs() {
  local base_dir="$1"
  log_info "创建账号数据目录结构..."

  mkdir -p "$base_dir/m7a-data/template"
  mkdir -p "$base_dir/m7a-data/accounts"

  if [ ! -f "$base_dir/m7a-data/template/config.yaml" ]; then
    cat > "$base_dir/m7a-data/template/config.yaml" << 'YAMLEOF'
# M7A 账号配置模板
# 完整配置参考: https://github.com/moesnow/March7thAssistant/blob/main/assets/config/config.example.yaml

cloud_game_enable: true
browser_headless_enable: true
after_finish: Loop
daily_enable: true
power_enable: true

# ---- 周常开关 ----
weekly_universe_enable: true
weekly_divergent_enable: true
forgottenhall_enable: true
purefiction_enable: true
apocalyptic_enable: true
echo_of_war_enable: true
fight_enable: false
currencywars_enable: false

# ---- 通知推送 ----
# notify_type: tg
# tg_bot_token: "your_bot_token"
# tg_chat_id: "your_chat_id"
YAMLEOF
    log_ok "配置文件模板已创建: $base_dir/m7a-data/template/config.yaml"
  fi

  touch "$base_dir/m7a-data/accounts/.gitkeep"
  log_ok "数据目录结构就绪"
  echo ""
}

# ---------------------------------------------------------------------------
# 后续步骤
# ---------------------------------------------------------------------------
print_next_steps() {
  echo ""
  echo -e "${CYAN}========================================"
  echo "  🎉 M7A Skill 安装完成！"
  echo -e "========================================${NC}"
  echo ""
  echo -e "  Skill 位置: ${PROJECT_DIR}/skills/m7a/SKILL.md"
  echo -e "  系统: ${OS}"
  echo ""
  echo -e "  ${CYAN}快速开始：${NC}"
  echo ""
  echo -e "  1. 创建账号配置："
  echo -e "     ${YELLOW}cp -r ${PROJECT_DIR}/m7a-data/template ${PROJECT_DIR}/m7a-data/accounts/main${NC}"
  echo -e "     ${YELLOW}编辑 m7a-data/accounts/main/config.yaml${NC}"
  echo ""
  echo -e "  2. 取消注释 docker-compose.yml 中的 m7a-main 服务，然后启动："
  echo -e "     ${YELLOW}cd ${PROJECT_DIR} && docker compose up -d${NC}"
  echo ""
  echo -e "  3. 在 AI 代理中触发任务："
  echo -e "     ${YELLOW}\"今天日常做了吗\"${NC} → 执行每日实训"
  echo -e "     ${YELLOW}\"清一下体力\"${NC}      → 清体力"
  echo ""
  echo -e "  ${CYAN}Star 支持:${NC} https://github.com/Jerry-zhuang/m7a-skill"
  echo ""
}

print_manual_hints() {
  echo ""
  echo -e "${YELLOW}未检测到已安装的 AI 代理，已为你完成基础安装。${NC}"
  echo ""
  echo -e "手动注册 skill 到各代理："
  echo ""
  echo -e "  ${CYAN}OpenClaw (龙虾):${NC}"
  echo "    openclaw skills add ${REPO_URL}"
  echo ""
  echo -e "  ${CYAN}Hermes (爱马仕):${NC}"
  echo "    hermes skills install https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/skills/m7a/SKILL.md"
  echo ""
  echo -e "  ${CYAN}opencode:${NC}"
  echo "    ln -sf ${PROJECT_DIR}/skills/m7a .opencode/skills/m7a"
  echo ""
  echo -e "  ${CYAN}Claude Code:${NC}"
  case "$OS" in
    windows) echo "    mklink /D %USERPROFILE%\\.claude\\skills\\m7a ${PROJECT_DIR}\\skills\\m7a" ;;
    *)       echo "    ln -sf ${PROJECT_DIR}/skills/m7a ~/.claude/skills/m7a" ;;
  esac
  echo ""
  echo -e "  ${YELLOW}Windows 用户也可使用 PowerShell 脚本:${NC}"
  echo "    https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/install.ps1"
  echo ""
  echo -e "  ${YELLOW}WSL 用户直接在 WSL 终端中运行此脚本即可。${NC}"
  echo ""
}

# =============================================================================
# 主流程
# =============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════╗"
  echo -e "║      🎮 M7A Skill 一键安装脚本          ║"
  echo -e "║  崩坏：星穹铁道 · Docker 多账号自动部署   ║"
  echo -e "║  适配: OpenClaw / Hermes / opencode / Claude Code"
  echo -e "║  支持: Linux / macOS / Windows (WSL)     ║"
  echo -e "╚══════════════════════════════════════════╝${NC}"
  echo ""

  check_prerequisites
  create_data_dirs "$PROJECT_DIR/"

  local installed=0
  install_openclaw   && installed=1 || true
  install_hermes     && installed=1 || true
  install_opencode   && installed=1 || true
  install_claudecode && installed=1 || true

  if [ "$installed" -eq 1 ]; then
    print_next_steps
  else
    print_manual_hints
  fi
}

main "$@"
