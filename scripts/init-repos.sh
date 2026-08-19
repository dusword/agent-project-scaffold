#!/usr/bin/env bash
# ============================================================================
# init-repos.sh · 把分发下来的模板重建成「独立嵌套仓库」
# ----------------------------------------------------------------------------
# 为什么需要这个脚本：
#
#   本体系的 git 约定是「每个项目自己一个完整仓库，父仓库 .gitignore 排除整个
#   projects/」（见 docs/00-架构规范.md §4）。但 GitHub 上一个仓库只能有一份
#   git 历史，所以**公开仓库是一份压平的快照**：文件全在，7 个嵌套仓库的 .git
#   一个都没有。
#
#   本脚本把那些仓库**建回来**：从仓库根往下找出每个「项目单元」，
#   给还没有 .git 的那些执行 git init + 启用提交硬闸 + 做一次首次提交。
#
# 判据：一个目录同时有 CLAUDE.md 和 .githooks/ → 它是一个项目单元。
#       （这两样正是本体系每个项目都必有的东西：宪法 + 提交硬闸）
#
# 幂等：已经有 .git 的单元一律跳过，只补一次 core.hooksPath 并回读验证。
#       所以重复跑没有副作用，clone 下来跑一次、以后想起来再跑一次都行。
#
# 🔴 关于这里用了 git add -A：
#   本体系的提交纪律是「一律 git add <显式路径>，不用 -A」，理由是 -A 会把没打算
#   提交的东西一起卷进来，而每次提交都要在 CHANGE-LOG 里对应一条记录。
#   **首次提交是这条纪律唯一说得通的例外**：此刻要提交的就是「这个项目单元的全部
#   出厂内容」，不存在「没打算提交的东西」，也没有别的写法能表达这个集合。
#   之后的每一次提交都回到显式路径。
#
# 用法：
#   bash scripts/init-repos.sh
# ============================================================================

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
root="$(cd "$script_dir/.." && pwd -P)"
cd "$root" || exit 1

# ---- 前置检查：git 得先知道你是谁，否则首次提交会失败在半路 ------------------
git_name="$(git config --get user.name 2>/dev/null || true)"
git_email="$(git config --get user.email 2>/dev/null || true)"
if [ -z "$git_name" ] || [ -z "$git_email" ]; then
  echo "❌ git 还不知道你是谁，首次提交一定会失败。先设置身份再回来跑本脚本：" >&2
  echo "" >&2
  echo "     git config --global user.name  \"你的名字\"" >&2
  echo "     git config --global user.email \"你的邮箱\"" >&2
  echo "" >&2
  exit 1
fi

# ---- 把 core.hooksPath 设成 .githooks 并**回读验证** ------------------------
# 相对路径 = 相对该仓库自己的根，所以每个单元各设一次，互不干扰。
ensure_hookspath() {
  git -C "$1" config core.hooksPath .githooks 2>/dev/null || return 1
  got="$(git -C "$1" config --get core.hooksPath 2>/dev/null || true)"
  [ "$got" = ".githooks" ]
}

# ---- 找出所有项目单元，按目录深度从浅到深排（父在子之前，读起来顺） ----------
units="$(
  find . -type f -name CLAUDE.md -not -path '*/.git/*' -print 2>/dev/null \
    | sed 's#/CLAUDE\.md$##; s#^\./CLAUDE\.md$#.#' \
    | while IFS= read -r d; do
        [ -d "$d/.githooks" ] && printf '%s\n' "$d"
      done \
    | awk '{ n = gsub("/", "/"); print n "\t" $0 }' \
    | sort -n -k1,1 \
    | cut -f2-
)"

if [ -z "$units" ]; then
  echo "❌ 一个项目单元都没找到（判据：目录里同时有 CLAUDE.md 和 .githooks/）。" >&2
  echo "   你是不是在错误的目录下跑的？本脚本应该待在模板仓库的 scripts/ 里。" >&2
  exit 1
fi

echo "在这棵树上找到以下项目单元（判据：同时有 CLAUDE.md 与 .githooks/）："
printf '%s\n' "$units" | sed 's#^\.$#  · <仓库根>#; s#^\./#  · #'
echo ""

created=0
skipped=0
failed=0

while IFS= read -r unit; do
  [ -z "$unit" ] && continue
  label="$(printf '%s' "$unit" | sed 's#^\.$#<仓库根>#; s#^\./##')"

  # ---- 已经是仓库 → 不碰历史，只保证提交硬闸是启用的 ----------------------
  if [ -d "$unit/.git" ] || [ -f "$unit/.git" ]; then
    if ensure_hookspath "$unit"; then
      echo "↷ 跳过（已是 git 仓库）：$label —— 已确认 core.hooksPath=.githooks"
      skipped=$((skipped + 1))
    else
      echo "🔴 失败：$label 已是 git 仓库，但 core.hooksPath 设不上（提交硬闸会静默失效）" >&2
      failed=$((failed + 1))
    fi
    continue
  fi

  # ---- 还没有仓库 → init + 启硬闸 + 首次提交 ------------------------------
  # -b main 需要 git ≥ 2.28；老版本走 symbolic-ref 兜底。
  if ! git -C "$unit" init -q -b main >/dev/null 2>&1; then
    if ! git -C "$unit" init -q >/dev/null 2>&1; then
      echo "🔴 失败：$label 的 git init 没成功" >&2
      failed=$((failed + 1))
      continue
    fi
    git -C "$unit" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || true
  fi

  if ! ensure_hookspath "$unit"; then
    echo "🔴 失败：$label 的 core.hooksPath 设不上（提交硬闸会静默失效，不继续提交）" >&2
    failed=$((failed + 1))
    continue
  fi

  git -C "$unit" add -A || {
    echo "🔴 失败：$label 的 git add 没成功" >&2
    failed=$((failed + 1))
    continue
  }

  # 首次提交天然过得了提交硬闸：CHANGE-LOG.md 与 README.md 本来就在暂存区里，
  # 而且相对空树整份 CHANGE-LOG 都算新增，记录行净增远大于 0。
  if ! commit_out="$(git -C "$unit" commit -q -m "chore: 从模板初始化仓库

分发下来的模板不带嵌套 git 历史（GitHub 一个仓库只能有一份历史），
本仓库由 scripts/init-repos.sh 重建，这是它的第一条提交。" 2>&1)"; then
    echo "🔴 失败：$label 的首次提交被拒绝。git 的输出：" >&2
    printf '%s\n' "$commit_out" | sed 's/^/     /' >&2
    failed=$((failed + 1))
    continue
  fi

  echo "✓ 已初始化：$label —— git init（main）+ 提交硬闸已启用 + 首次提交完成"
  created=$((created + 1))
done <<EOF
$units
EOF

echo ""
echo "———— 结果 ————"
echo "新建仓库：$created 个    跳过（本来就有）：$skipped 个    失败：$failed 个"

if [ "$failed" -gt 0 ]; then
  echo ""
  echo "🔴 有 $failed 个单元没处理成，上面每条都写了原因。修掉之后重跑本脚本即可（幂等）。" >&2
  exit 1
fi

cat <<'TIP'

接下来做什么：
  1. 复制模具开自己的项目 —— 见 docs/01-使用指南.md §4
     （模具在 projects/main-sub-architecture-project-demo/）
  2. 想验证提交硬闸真的在管事，随便改个文件不带日志提交一次，应当被拒绝：
       cd projects/main-sub-architecture-project-demo
       echo x >> README.md && git add README.md && git commit -m test    # 应当被拒
  3. 在任何项目目录里开 Claude 会话，确立仪式会自动来找你。
TIP

# ---- 只在真的有重叠时才提醒，免得说一件不存在的事（本体系最贵的错误是乐观假陈述）
root_tracks_projects="$(git -C "$root" ls-files projects/ 2>/dev/null | head -1)"
if [ -n "$root_tracks_projects" ]; then
  cat <<'WARN'

⚠️  一件要知道的事（`git clone` 下来的才有）：
    本仓库根**也在跟踪 projects/ 下的文件**——公开仓库是压平快照，那些文件是随分发
    一起进来的，而 git 对**已跟踪**的文件不再看 .gitignore。所以在根目录 git status
    会看到子项目的改动，这跟本体系「父仓库看不见子项目改动」的说法不一致。

    这是分发形态的产物，不是模板的行为：你按 docs/01-使用指南.md 复制模具建出来的
    项目，父仓库从第一天起就 .gitignore 排除 projects/，行为是对的。
    想让手上这一份也干净，两条路：改用 GitHub 的 zip 下载（压缩包里没有 .git，
    跑完本脚本得到的就是完全正确的形状）；或者在根仓库执行
      git rm -r --cached projects/
    然后提交 —— 提交时硬闸会要求你在 CHANGE-LOG 里记一行，那正是它该做的事。
WARN
fi
