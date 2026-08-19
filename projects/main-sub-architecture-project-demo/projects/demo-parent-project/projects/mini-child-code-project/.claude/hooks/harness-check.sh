#!/usr/bin/env bash
# ============================================================================
# 确立仪式触发器 · harness-check.sh
# ----------------------------------------------------------------------------
# 挂在 SessionStart 上。每次开会话时检查 .claude/HARNESS-STATUS.md，
# 判定本项目的 harness（宪法 + 规矩 + 钩子）是否已经针对**本项目**确立过。
#
# 判定为「未确立」的三种情况：
#   ① .claude/HARNESS-STATUS.md 不存在
#   ② 状态行写着「## 当前状态：未确立」（行首锚定的完整前缀，不是全文找关键词）
#   ③ 🔴 文件里记录的项目名 ≠ 当前目录名
#
# 第 ③ 条是整套体系的关键机关：
#   模板 / demo 被复制到新目录并改名后，记录的名字对不上新目录名，
#   仪式自动重新触发 —— 不需要任何重置脚本，也不可能忘记重置。
#
# 未确立 → 往上下文打印一段指令（SessionStart 的 stdout 会作为上下文给到
# Claude），要求 agent 先完成确立仪式再做别的事。
# 已确立 → 一声不吭，零噪音。
#
# 退出码在 SessionStart 上被忽略，一律返回 0。
# ============================================================================

set -u

# 消费掉 stdin 的 JSON（本钩子用不到，但要读掉，避免上游写管道时报错）
cat >/dev/null 2>&1 || true

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
project_root="$(cd "$project_dir" 2>/dev/null && pwd -P)" || exit 0
project_name="$(basename "$project_root")"
status_file="$project_root/.claude/HARNESS-STATUS.md"

reason=""

if [ ! -f "$status_file" ]; then
  reason="缺少 .claude/HARNESS-STATUS.md（这个项目从来没做过确立仪式）"
elif grep -q "^## 当前状态：未确立" "$status_file" 2>/dev/null; then
  reason="HARNESS-STATUS.md 里写着「未确立」"
else
  recorded="$(sed -n 's/^- 项目名：[[:space:]]*//p' "$status_file" 2>/dev/null \
    | head -1 | tr -d '[:space:]' | tr -d '`')"
  if [ -z "$recorded" ]; then
    reason="HARNESS-STATUS.md 里读不到「- 项目名：」这一行（格式被破坏或从未填写）"
  elif [ "$recorded" != "$project_name" ]; then
    reason="HARNESS-STATUS.md 记录的项目名是「$recorded」，而当前目录名是「$project_name」——说明这份 harness 是从别处复制来的，还没针对本项目确立"
  fi
fi

# 已确立：安静退出
[ -z "$reason" ] && exit 0

cat <<EOF
================================================================================
🔴 本项目的 harness 尚未确立 —— 这是本次会话的第一要务，先做完再做别的事。

判定依据：$reason
当前项目：$project_name
状态文件：.claude/HARNESS-STATUS.md

请引导用户完成「确立仪式」，四步，按顺序做：

  ① 读背景
     读 README.md、docs/ 下的文档、CLAUDE.md（项目根）、.claude/rules/ 全部规矩。
     搞清楚：这是个什么项目、属于哪一类（代码 / 实验 / 文档 / 父项目）、
     它现在继承的默认规矩是什么。

  ② 问用户 3~5 个问题（一次问完，不要挤牙膏）
     · 这个项目的目标是什么？交付物是什么形态？
     · 有没有本项目特有的纪律？（例如：花钱前要报预算 / 上线前要人工验收）
     · 继承来的默认规矩里，有哪条要改或要删？
     · 有没有需要提前说清的边界？（不许碰什么、必须先问什么）
     · 这个项目会不会再往下嵌子项目？

  ③ 按需修改 CLAUDE.md（项目根，以及需要时的 .claude/rules/）
     🔴 允许一字不改沿用默认宪法 —— 那也是一个有效的确立结果，
        只要在第 ④ 步如实写明「沿用默认，未作改动」即可。

  ④ 把结果写进 .claude/HARNESS-STATUS.md
     必须包含这四项，且「- 项目名：」那一行必须**精确等于当前目录名**
     （$project_name），否则下次开会话还会再触发一次仪式：

       - 项目名：$project_name
       - 确立日期：$(date +%Y-%m-%d)
       - 确认人：<用户名字>
       - 改动摘要：<改了哪几条 / 或写「沿用默认，未作改动」>

完成这四步之前，不要开始任何开发、实验或写文档的工作。
如果用户明确说「先跳过仪式，我赶时间」——照办，但要告诉他下次开会话还会再提示。
================================================================================
EOF

exit 0
