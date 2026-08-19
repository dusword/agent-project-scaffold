#!/usr/bin/env bash
# ============================================================================
# 越界拦截 · boundary-guard.sh
# ----------------------------------------------------------------------------
# 挂在 PreToolUse（matcher: Write|Edit）上。
# 作用：agent 只许写自己这棵项目树里的文件。目标落在项目树外 → 退出码 2 阻止。
#
# 放行口（唯一）：项目根下存在 .claude/cross-edit-allow 放行条，且
#   ① 文件修改时间在 30 分钟以内（过期自动失效，不用记得删）
#   ② 文件里某一行是目标路径的前缀
# 授权流程写在 .claude/rules/boundary.md。
#
# 🔴 已知局限（如实说明，不要以为它是铁桶）：
#   · 只拦 Write / Edit 两个工具。用 Bash 写文件（cat > / sed -i / cp）绕得过去。
#   · 只拦 agent，人类手动改文件不经过它。
#   靠这两条兜底：rules/boundary.md 的纪律 + 对方仓库自己的 pre-commit 硬闸。
#
# 依赖：优先 jq，其次 python3，最后正则兜底。三者都没有也不会误杀（放行）。
# ============================================================================

set -u

input="$(cat)"

# ---- 只管 Write / Edit，其它一律放行 ---------------------------------------
extract() {
  # $1 = jq 路径, $2 = python 键路径描述
  printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
}

tool_name=""
file_path=""

if command -v jq >/dev/null 2>&1; then
  tool_name="$(extract '.tool_name')"
  file_path="$(extract '.tool_input.file_path')"
fi

if [ -z "$file_path" ] && command -v python3 >/dev/null 2>&1; then
  parsed="$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input") or {}
print(d.get("tool_name") or "")
print(ti.get("file_path") or "")
' 2>/dev/null)"
  if [ -n "$parsed" ]; then
    tool_name="$(printf '%s\n' "$parsed" | sed -n '1p')"
    file_path="$(printf '%s\n' "$parsed" | sed -n '2p')"
  fi
fi

if [ -z "$file_path" ]; then
  # 正则兜底：抓第一个 "file_path": "..."
  file_path="$(printf '%s' "$input" \
    | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi

# 解析不出目标路径 → 放行（钩子的职责是拦越界，不是给正常工作添堵）
[ -z "$file_path" ] && exit 0

case "$tool_name" in
  ""|Write|Edit|MultiEdit|NotebookEdit) : ;;
  *) exit 0 ;;
esac

# ---- 确定项目根 ------------------------------------------------------------
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
project_root="$(cd "$project_dir" 2>/dev/null && pwd -P)" || exit 0
[ -z "$project_root" ] && exit 0

# ---- 把目标路径规范成绝对真实路径（文件可能还不存在，所以从父目录解析）-----
abspath() {
  p="$1"
  case "$p" in
    /*) : ;;
    *) p="$project_root/$p" ;;
  esac
  d="$(dirname "$p")"
  b="$(basename "$p")"
  # 向上找到第一个真实存在的祖先目录，解析它，再把剩下的段拼回去
  suffix="$b"
  while [ ! -d "$d" ] && [ "$d" != "/" ] && [ -n "$d" ]; do
    suffix="$(basename "$d")/$suffix"
    d="$(dirname "$d")"
  done
  real_d="$(cd "$d" 2>/dev/null && pwd -P)" || real_d="$d"
  printf '%s/%s' "${real_d%/}" "$suffix"
}

target="$(abspath "$file_path")"

# ---- 在项目树内 → 放行 ------------------------------------------------------
case "$target" in
  "$project_root"|"$project_root"/*) exit 0 ;;
esac

# ---- 放行条检查 ------------------------------------------------------------
allow_file="$project_root/.claude/cross-edit-allow"
allow_note=""

if [ -f "$allow_file" ]; then
  now="$(date +%s)"
  mtime="$(stat -f %m "$allow_file" 2>/dev/null || stat -c %Y "$allow_file" 2>/dev/null || echo 0)"
  age=$(( now - mtime ))
  if [ "$age" -le 1800 ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      # 去注释与首尾空白
      line="${line%%#*}"
      line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -z "$line" ] && continue
      # 去掉结尾斜杠，避免 /a/b/ 被 abspath 解析成 /a/b/b
      while [ "${line%/}" != "$line" ] && [ "$line" != "/" ]; do line="${line%/}"; done
      [ -z "$line" ] && continue
      # 放行条允许写绝对路径，也允许写相对本项目根的路径
      prefix="$(abspath "$line")"
      [ -z "$prefix" ] && continue
      case "$target" in
        "$prefix"|"$prefix"*) exit 0 ;;
      esac
    done < "$allow_file"
    allow_note="放行条存在且未过期（剩余 $(( (1800 - age) / 60 )) 分钟），但没有一行能覆盖这个目标路径。"
  else
    allow_note="放行条存在但已过期（$(( age / 60 )) 分钟前写的，上限 30 分钟）——请重新走一次授权流程。"
  fi
else
  allow_note="当前没有放行条（$project_root/.claude/cross-edit-allow 不存在）。"
fi

# ---- 拦截 ------------------------------------------------------------------
{
  echo "🚫 越界写入被拦截（boundary-guard）"
  echo ""
  echo "   本项目根：$project_root"
  echo "   目标路径：$target"
  echo "   目标不在本项目树内，已阻止本次 Write/Edit。"
  echo ""
  echo "   $allow_note"
  echo ""
  echo "   下一步该怎么做（照做，别绕路）："
  echo "     1) 停下来，告诉用户你需要改本项目之外的哪个文件、为什么。"
  echo "     2) 等用户口头同意后，在本项目写放行条："
  echo "        .claude/cross-edit-allow  每行一个被授权的路径前缀"
  echo "     3) 改完提醒用户：对方项目提交时会被对方的 pre-commit 硬闸要求补 CHANGE-LOG.md。"
  echo "     4) 删掉放行条（忘了也没关系，30 分钟后自动失效）。"
  echo ""
  echo "   完整流程见本项目 .claude/rules/boundary.md。"
  echo "   ⚠️ 不要改用 Bash 写文件来绕过本钩子 —— 那是明知故犯，不是变通。"
} >&2

exit 2
