#!/usr/bin/env bash
# =============================================================================
# M7A Skill — 一键安装脚本（支持 OpenClaw / Hermes / opencode / Claude Code）
# =============================================================================
# 用法:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/install.sh)
#
# 自动检测当前环境中的 AI 编码代理，将 skill 安装到正确位置。
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/Jerry-zhuang/m7a-skill.git"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# -------------------------------------------------------------------------
# 安装 skill 到目标目录（创建 symlink）
# -------------------------------------------------------------------------
install_skill() {
  local platform="$1"
  local target_dir="$2"
  local source_path="${PROJECT_DIR}/skills/m7a"

  mkdir -p "$(dirname "$target_dir")"

  if [ -L "$target_dir" ] || [ -d "$target_dir" ]; then
    log_info "${platform}: 已存在，跳过 (${target_dir})"
    return 0
  fi

  ln -sf "$source_path" "$target_dir"
  log_ok "${platform}: skill 已安装 → ${target_dir}"
}

# -------------------------------------------------------------------------
# 检测并安装各平台
# -------------------------------------------------------------------------
install_openclaw() {
  local dir="${OPENCLAW_SKILLS_DIR:-$HOME/.openclaw/skills/m7a}"
  if [ -n "${OPENCLAW_SKILLS_DIR:-}" ] || [ -d "$HOME/.openclaw/skills" ]; then
    install_skill "OpenClaw (龙虾)" "$dir"
    return 0
  fi
  return 1
}

install_hermes() {
  local dir="${HERMES_SKILLS_DIR:-$HOME/.hermes/skills/m7a}"
  if [ -n "${HERMES_SKILLS_DIR:-}" ] || [ -d "$HOME/.hermes/skills" ]; then
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
  local dir="$HOME/.claude/skills/m7a"
  if [ -d "$HOME/.claude/skills" ]; then
    install_skill "Claude Code" "$dir"
    return 0
  fi
  # 也检查项目级 .claude/skills
  local project_dir="./.claude/skills/m7a"
  if [ -d "./.claude/skills" ]; then
    install_skill "Claude Code (project)" "$project_dir"
    return 0
  fi
  return 1
}

# -------------------------------------------------------------------------
# 前置检查
# -------------------------------------------------------------------------
check_prerequisites() {
  log_info "检查前置依赖..."
  local has_docker=false

  if command -v docker &>/dev/null; then
    log_ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
    has_docker=true
  else
    log_warn "Docker 未安装。M7A 需要 Docker Engine >= 20.10。"
  fi

  if docker compose version &>/dev/null; then
    log_ok "Docker Compose $(docker compose version | awk '{print $4}' | tr -d ',')"
  else
    log_warn "Docker Compose V2 未安装。"
  fi

  echo ""
  $has_docker || log_warn "请先安装 Docker: https://docs.docker.com/engine/install/"
  echo ""
}

# -------------------------------------------------------------------------
# 创建账号数据目录
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# 后续步骤
# -------------------------------------------------------------------------
print_next_steps() {
  echo ""
  echo -e "${CYAN}========================================"
  echo "  🎉 M7A Skill 安装完成！"
  echo -e "========================================${NC}"
  echo ""
  echo -e "  Skill 位置: ${PROJECT_DIR}/skills/m7a/SKILL.md"
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
  echo "    ln -sf ${PROJECT_DIR}/skills/m7a ~/.claude/skills/m7a"
  echo ""
}

# =============================================================================
# 主流程
# =============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗"
  echo -e "║    🎮 M7A Skill 一键安装脚本        ║"
  echo -e "║    适配: OpenClaw / Hermes / opencode / Claude Code"
  echo -e "╚══════════════════════════════════════╝${NC}"
  echo ""

  check_prerequisites
  create_data_dirs "$PROJECT_DIR/"

  local installed=0

  install_openclaw && installed=1 || true
  install_hermes   && installed=1 || true
  install_opencode && installed=1 || true
  install_claudecode && installed=1 || true

  if [ "$installed" -eq 1 ]; then
    print_next_steps
  else
    print_manual_hints
  fi
}

main "$@"
