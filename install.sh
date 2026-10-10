#!/usr/bin/env bash
# 安装 ppt-one-stop 及其依赖技能到 DSH / Agents 技能目录。
#
#   ./install.sh                      # 从默认仓库地址克隆并安装
#   ./install.sh --repo <git-url>     # 从指定地址安装
#   ./install.sh --local <dir>        # 从本地仓库目录安装（离线/测试用）
#   ./install.sh --home <dir>         # 装到非默认主目录
#   ./install.sh --dry-run            # 只打印将要执行的动作
#
# 安装目标： <home>/.dsh/skills/  和  <home>/.agents/skills/

set -euo pipefail

REPO_URL="https://github.com/OWNER/ppt-one-stop.git"
LOCAL_DIR=""
HOME_OVERRIDE=""
DRY_RUN=0
SKILLS=(ppt-one-stop ppt-content-generation ppt-visual-design)

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)     REPO_URL="$2"; shift 2 ;;
    --local)    LOCAL_DIR="$2"; shift 2 ;;
    --home)     HOME_OVERRIDE="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)  usage ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

HOME_DIR="${HOME_OVERRIDE:-$HOME}"
if [ -z "$HOME_DIR" ]; then
  say "错误: 无法确定目标主目录，请用 --home 指定" >&2
  exit 1
fi
DSH_SKILLS="$HOME_DIR/.dsh/skills"
AGENTS_SKILLS="$HOME_DIR/.agents/skills"
ROOTS=("$DSH_SKILLS" "$AGENTS_SKILLS")

# ── 取得仓库 ────────────────────────────────────────────────────────────
WORK_DIR=""
cleanup() { [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"; }
trap cleanup EXIT

if [ -n "$LOCAL_DIR" ]; then
  [ -d "$LOCAL_DIR/skills" ] || { say "错误: $LOCAL_DIR 下没有 skills/ 目录" >&2; exit 1; }
  SRC="$LOCAL_DIR"
  say "使用本地仓库: $SRC"
else
  say "克隆仓库: $REPO_URL"
  if [ "$DRY_RUN" -eq 1 ]; then
    say "  [dry-run] git clone --depth 1 $REPO_URL <临时目录>"
    SRC="<未克隆>"
  else
    command -v git >/dev/null 2>&1 || { say "错误: 需要 git" >&2; exit 1; }
    WORK_DIR="$(mktemp -d)"
    git clone --depth 1 "$REPO_URL" "$WORK_DIR/repo" >/dev/null 2>&1 \
      || { say "错误: 克隆失败，请检查仓库地址是否正确且可公开访问" >&2; exit 1; }
    SRC="$WORK_DIR/repo"
  fi
fi

# ── 安装 ────────────────────────────────────────────────────────────────
say ""
say "安装技能到 ${ROOTS[*]}"
INSTALLED=()
FAILED=()

for skill in "${SKILLS[@]}"; do
  src_skill="$SRC/skills/$skill"
  if [ ! -d "$src_skill" ] || [ ! -f "$src_skill/SKILL.md" ]; then
    say "  ✗ $skill — 仓库中缺少 SKILL.md，跳过"
    FAILED+=("$skill")
    continue
  fi
  for root in "${ROOTS[@]}"; do
    mkdir -p "$root/$skill"
    # 覆盖同名文件，不删除目标目录中的其他内容
    if [ "$DRY_RUN" -eq 1 ]; then
      say "  [dry-run] 复制 $src_skill/* -> $root/$skill/"
    else
      cp -R "$src_skill/." "$root/$skill/"
    fi
  done
  say "  ✓ $skill"
  INSTALLED+=("$skill")
done

# ── 校验 ────────────────────────────────────────────────────────────────
say ""
say "校验"
for skill in "${INSTALLED[@]}"; do
  for root in "${ROOTS[@]}"; do
    f="$root/$skill/SKILL.md"
    if [ "$DRY_RUN" -eq 1 ]; then
      say "  [dry-run] 校验 $f"
      continue
    fi
    if [ ! -f "$f" ]; then
      say "  ✗ $f 不存在"
      FAILED+=("$skill")
      continue
    fi
    if ! head -n 20 "$f" | grep -q '^name:'; then
      say "  ✗ $f 缺少 name 字段"
      FAILED+=("$skill")
      continue
    fi
    name="$(head -n 20 "$f" | sed -n 's/^name:[[:space:]]*//p' | head -n 1 | tr -d '"'"'" | tr -d '\r')"
    if ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      say "  ✗ $f 的 name 不是 kebab-case: $name"
      FAILED+=("$skill")
      continue
    fi
    if ! head -n 20 "$f" | grep -q '^description:'; then
      say "  ✗ $f 缺少 description 字段"
      FAILED+=("$skill")
      continue
    fi
  done
done

# ── 结果 ────────────────────────────────────────────────────────────────
say ""
say "安装结果"
for skill in "${INSTALLED[@]}"; do
  for root in "${ROOTS[@]}"; do
    say "  $skill -> $root/$skill/"
  done
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  say ""
  say "有问题的技能: ${FAILED[*]}" >&2
  exit 1
fi

say ""
say "完成。修改即时生效，无需重启 DSH。"
say "用法：直接对 DSH 说「帮我做个项目汇报 PPT」，它会一步步问你要需求。"