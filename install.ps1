<#
.SYNOPSIS
  M7A Skill — 一键安装脚本（Windows PowerShell）
.DESCRIPTION
  崩坏：星穹铁道 三月七小助手 Docker 多账号自动部署 Skill。
  自动检测 OpenClaw / Hermes / opencode / Claude Code 等 AI 代理并安装。
  支持 Windows 10/11 (PowerShell 5.1+).
.LINK
  https://github.com/Jerry-zhuang/m7a-skill
.EXAMPLE
  # 直接运行（推荐）
  irm https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/install.ps1 | iex

  # 或下载后运行
  .\install.ps1
#>

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/Jerry-zhuang/m7a-skill.git"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ProjectDir -or $ProjectDir -eq "") { $ProjectDir = (Get-Location).Path }

$HomeDir = $env:USERPROFILE
if (-not $HomeDir) { $HomeDir = $env:HOME }

function Write-Info  { Write-Host "[INFO]  $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "[OK]    $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[WARN]  $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# 检测 AI 代理技能目录是否存在
# ---------------------------------------------------------------------------
function Test-SkillDir {
  param([string]$Path)
  return (Test-Path $Path)
}

# ---------------------------------------------------------------------------
# 安装 skill（创建 symlink 或 copy）
# ---------------------------------------------------------------------------
function Install-Skill {
  param([string]$Platform, [string]$TargetDir)
  $sourcePath = Join-Path $ProjectDir "skills\m7a"

  $parentDir = Split-Path $TargetDir -Parent
  if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

  if (Test-Path $TargetDir) {
    Write-Info "$Platform : 已存在，跳过 ($TargetDir)"
    return $true
  }

  # 尝试创建 symlink（需要管理员或开发者模式）
  try {
    New-Item -ItemType SymbolicLink -Path $TargetDir -Target $sourcePath -Force | Out-Null
    Write-Ok "$Platform : skill 已安装 → $TargetDir"
  } catch {
    # 降级为 copy
    Copy-Item -Path $sourcePath -Destination $TargetDir -Recurse -Force
    Write-Ok "$Platform : skill 已安装 (copy fallback) → $TargetDir"
  }
  return $true
}

# ---------------------------------------------------------------------------
# 检测并安装各平台
# ---------------------------------------------------------------------------
function Install-OpenClaw {
  $dir = Join-Path $HomeDir ".openclaw\skills\m7a"
  $parent = Split-Path $dir -Parent
  if (Test-Path $parent) { return Install-Skill "OpenClaw (龙虾)" $dir }
  return $false
}

function Install-Hermes {
  $dir = Join-Path $HomeDir ".hermes\skills\m7a"
  $parent = Split-Path $dir -Parent
  if (Test-Path $parent) { return Install-Skill "Hermes (爱马仕)" $dir }
  return $false
}

function Install-Opencode {
  $dir = Join-Path (Get-Location).Path ".opencode\skills\m7a"
  $parent = Split-Path $dir -Parent
  if (Test-Path $parent) { return Install-Skill "opencode" $dir }
  return $false
}

function Install-ClaudeCode {
  $dir = Join-Path $HomeDir ".claude\skills\m7a"
  $parent = Split-Path $dir -Parent
  if (Test-Path $parent) { return Install-Skill "Claude Code" $dir; return $true }
  # 也检查项目级
  $projectDir = Join-Path (Get-Location).Path ".claude\skills\m7a"
  $projectParent = Split-Path $projectDir -Parent
  if (Test-Path $projectParent) { return Install-Skill "Claude Code (project)" $projectDir; return $true }
  return $false
}

# ---------------------------------------------------------------------------
# 前置检查
# ---------------------------------------------------------------------------
function Check-Prerequisites {
  Write-Info "检查前置依赖..."

  # 检查 Docker
  $docker = Get-Command docker -ErrorAction SilentlyContinue
  if ($docker) {
    $ver = & docker --version 2>$null
    Write-Ok "Docker $ver"
  } else {
    Write-Warn "Docker 未安装。M7A 需要 Docker Desktop for Windows。"
    Write-Warn "下载: https://docs.docker.com/desktop/install/windows-install/"
  }

  # 检查 Docker Compose
  $compose = & docker compose version 2>$null
  if ($LASTEXITCODE -eq 0) {
    Write-Ok "Docker Compose $compose"
  } else {
    Write-Warn "Docker Compose V2 未安装。"
  }

  Write-Host ""
}

# ---------------------------------------------------------------------------
# 创建数据目录
# ---------------------------------------------------------------------------
function Create-DataDirs {
  param([string]$BaseDir)
  Write-Info "创建账号数据目录结构..."

  $templateDir = Join-Path $BaseDir "m7a-data\template"
  $accountsDir = Join-Path $BaseDir "m7a-data\accounts"

  New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
  New-Item -ItemType Directory -Path $accountsDir -Force | Out-Null

  $configPath = Join-Path $templateDir "config.yaml"
  if (-not (Test-Path $configPath)) {
    @"
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
"@ | Out-File -FilePath $configPath -Encoding utf8
    Write-Ok "配置文件模板已创建: $configPath"
  }

  $gitkeep = Join-Path $accountsDir ".gitkeep"
  if (-not (Test-Path $gitkeep)) { New-Item -ItemType File -Path $gitkeep -Force | Out-Null }
  Write-Ok "数据目录结构就绪"
  Write-Host ""
}

# ---------------------------------------------------------------------------
# 后续步骤
# ---------------------------------------------------------------------------
function Print-NextSteps {
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host "  🎉 M7A Skill 安装完成！" -ForegroundColor Cyan
  Write-Host "========================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Skill 位置: $ProjectDir\skills\m7a\SKILL.md"
  Write-Host ""
  Write-Host "  快速开始：" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  1. 创建账号配置："
  Write-Host "     Copy-Item -Path $ProjectDir\m7a-data\template -Destination $ProjectDir\m7a-data\accounts\main -Recurse" -ForegroundColor Yellow
  Write-Host "     编辑 m7a-data\accounts\main\config.yaml" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  2. 取消注释 docker-compose.yml 中的 m7a-main 服务，然后启动："
  Write-Host "     cd $ProjectDir ; docker compose up -d" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  3. 在 AI 代理中触发任务："
  Write-Host '     "今天日常做了吗" → 执行每日实训' -ForegroundColor Yellow
  Write-Host '     "清一下体力"      → 清体力' -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  Star 支持: https://github.com/Jerry-zhuang/m7a-skill" -ForegroundColor Cyan
  Write-Host ""
}

function Print-ManualHints {
  Write-Host ""
  Write-Host "未检测到已安装的 AI 代理，已为你完成基础安装。" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "手动注册 skill 到各代理："
  Write-Host ""
  Write-Host "  OpenClaw (龙虾):" -ForegroundColor Cyan
  Write-Host "    openclaw skills add $RepoUrl"
  Write-Host ""
  Write-Host "  Hermes (爱马仕):" -ForegroundColor Cyan
  Write-Host "    hermes skills install https://raw.githubusercontent.com/Jerry-zhuang/m7a-skill/main/skills/m7a/SKILL.md"
  Write-Host ""
  Write-Host "  opencode:" -ForegroundColor Cyan
  Write-Host "    mkdir -p .opencode/skills"
  Write-Host "    cd .opencode/skills"
  Write-Host "    New-Item -ItemType SymbolicLink -Path m7a -Target $ProjectDir\skills\m7a"
  Write-Host ""
  Write-Host "  Claude Code:" -ForegroundColor Cyan
  Write-Host "    New-Item -ItemType SymbolicLink -Path $HomeDir\.claude\skills\m7a -Target $ProjectDir\skills\m7a"
  Write-Host ""
  Write-Host "  注意: symlink 需要管理员权限或开启开发者模式。" -ForegroundColor Yellow
  Write-Host "  如果失败，可使用: Copy-Item -Path ... -Destination ... -Recurse" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  WSL 用户建议直接在 WSL 终端中使用 install.sh。" -ForegroundColor Yellow
  Write-Host ""
}

# =============================================================================
# 主流程
# =============================================================================
function Main {
  Write-Host ""
  Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║      🎮 M7A Skill 一键安装脚本          ║" -ForegroundColor Cyan
  Write-Host "║  崩坏：星穹铁道 · Docker 多账号自动部署   ║" -ForegroundColor Cyan
  Write-Host "║  适配: OpenClaw / Hermes / opencode / Claude Code" -ForegroundColor Cyan
  Write-Host "║  支持: Windows 10/11 (PowerShell)        ║" -ForegroundColor Cyan
  Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""

  Check-Prerequisites
  Create-DataDirs $ProjectDir

  $installed = $false
  if (Install-OpenClaw)   { $installed = $true }
  if (Install-Hermes)     { $installed = $true }
  if (Install-Opencode)   { $installed = $true }
  if (Install-ClaudeCode) { $installed = $true }

  if ($installed) {
    Print-NextSteps
  } else {
    Print-ManualHints
  }
}

Main
