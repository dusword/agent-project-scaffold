#!/usr/bin/env bash
# ============================================================================
# init-repos.sh · 把分发下来的压平快照还原成一个**可用的** git 仓库
# ----------------------------------------------------------------------------
# 为什么需要这个脚本：
#
#   公开仓库是一份**压平的快照**：文件全在，**源头的 git 历史一律不随分发**
#   （这是死规矩，不是技术限制，理由见 docs/03-发布与同步.md §1 那条铁律）。
#
#   而本体系的提交硬闸靠的是仓库的**本地配置** core.hooksPath：
#     · zip 下载的那一份 —— 连 .git 都没有，更谈不上 hooksPath；
#     · git clone 的那一份 —— 有 .git，但 core.hooksPath 是本地配置，**从不随 clone 过来**。
#   两种情况下硬闸都**静默失效**：不报错，只是「改动必留日志」这套纪律一声不吭地不存在。
#   本脚本就是把它补回来。
#
# 🔴 只还原**一个**仓库：你 clone / 解压出来的这个根目录（口径 2026-08-25 起）。
#   本模板仓库自己是**单一仓库**（展馆模式，docs/02-设计决策.md D11）——模具与四类
#   demo 都是它跟踪的展品，没有各自的 .git，所以还原时也只需要一个仓库。
#
#   ⚠️ 别把这条读成体系的架构。体系教给真实项目的仍然是「每个项目自己 git init、
#      父仓库 .gitignore 排除整个 projects/」（D1 维持原判，见 docs/00-架构规范.md §4）。
#      你照 docs/01-使用指南.md §4 复制模具建出来的项目是**那套**形态，与本脚本无关。
#
# 幂等：根目录已经是 git 仓库（clone 的情况）→ **不碰历史**，只补设 core.hooksPath
#       并回读验证。所以重复跑没有副作用，想起来就再跑一次也行。
#
# 🔴 关于这里用了 git add -A（以及给展品补的 git add -f）：
#   本体系的提交纪律是「一律 git add <显式路径>，不用 -A」，理由是 -A 会把没打算提交
#   的东西一起卷进来，而每次提交都要在 CHANGE-LOG 里对应一条记录。
#   **首次提交是这条纪律唯一说得通的例外**：此刻要提交的就是「这份快照的全部内容」，
#   不存在「没打算提交的东西」，也没有别的写法能表达这个集合。
#   之后的每一次提交都回到显式路径。
#
# 用法：
#   bash scripts/init-repos.sh
# ============================================================================

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
root="$(cd "$script_dir/.." && pwd -P)"
cd "$root" || exit 1

# ---- 前置检查：这里得像个模板仓库，不然多半是在错误的目录下跑的 --------------
if [ ! -f "$root/CLAUDE.md" ] || [ ! -d "$root/.githooks" ]; then
  echo "❌ 这个目录不像本模板的根（缺 CLAUDE.md 或 .githooks/）。" >&2
  echo "   本脚本应该待在模板仓库的 scripts/ 里，用 'bash scripts/init-repos.sh' 调用。" >&2
  exit 1
fi

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
# 只设不读是不够的：设失败时 git 未必吭声，而结果是硬闸静默失效——
# 本体系最怕的就是这种「不报错的失效」。
ensure_hookspath() {
  git config core.hooksPath .githooks 2>/dev/null || return 1
  got="$(git config --get core.hooksPath 2>/dev/null || true)"
  [ "$got" = ".githooks" ]
}

# ---- 树里如果还有嵌套 .git，说明这份树不是干净的快照 ------------------------
# 干净的分发快照里除了根目录之外**不该有任何 .git**（rsync 导出时排掉了）。
# 有的话只可能是两种来路：旧形态（每个项目各自一个仓库）留下的残留，
# 或者你自己在某个子目录里 git init 过。两种都不归本脚本管，但要说出来。
nested_git="$(find . -mindepth 2 -name .git \
                 -not -path './.git/*' \
                 -not -path './.migration-backup/*' \
                 -prune -print 2>/dev/null | sed 's#^\./##' | sort)"

if [ -n "$nested_git" ]; then
  {
    echo ""
    echo "⚠️  树里发现了嵌套的 .git（本脚本不碰它们，只是告诉你一声）："
    printf '%s\n' "$nested_git" | sed 's/^/     · /'
    echo ""
    echo "    干净的分发快照里除了根目录之外不该有 .git。这多半是**旧形态的残留**："
    echo "    2026-08-25 之前本模板仓库自己也是「每个项目单元各一个嵌套仓库」，"
    echo "    现在它是单一仓库（展馆模式，docs/02-设计决策.md D11）。"
    echo "    留着它们不会弄坏什么，但根仓库不会跟踪它们里面的内容；"
    echo "    想要一份形态干净的树，用 GitHub 的 zip 下载重新拿一份。"
    echo ""
  } >&2
fi

# ---- 情况一：根目录已经是 git 仓库（git clone 来的）------------------------
# 不碰历史、不做提交，只保证提交硬闸是启用的。
if [ -d "$root/.git" ] || [ -f "$root/.git" ]; then
  if ensure_hookspath; then
    echo "↷ 根目录已经是 git 仓库（多半是 git clone 来的）：不碰历史。"
    echo "✓ 已确认 core.hooksPath=.githooks —— 提交硬闸从现在起生效。"
  else
    echo "🔴 失败：根目录已是 git 仓库，但 core.hooksPath 设不上（提交硬闸会静默失效）" >&2
    exit 1
  fi
else
  # ---- 情况二：还没有仓库（zip 下载来的）→ init + 启硬闸 + 首次提交 --------
  # -b main 需要 git ≥ 2.28；老版本走 symbolic-ref 兜底。
  if ! git init -q -b main >/dev/null 2>&1; then
    if ! git init -q >/dev/null 2>&1; then
      echo "🔴 失败：git init 没成功" >&2
      exit 1
    fi
    git symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || true
  fi

  if ! ensure_hookspath; then
    echo "🔴 失败：core.hooksPath 设不上（提交硬闸会静默失效，不继续提交）" >&2
    exit 1
  fi

  git add -A || { echo "🔴 失败：git add 没成功" >&2; exit 1; }

  # ---- 补上被「出厂形态的 .gitignore」挡在门外的展品 ----------------------
  # 模具与 demo-parent-project 自己的 .gitignore 里写着 projects/ —— 那是它们要
  # 教给真实项目的形态（父仓库排除 projects/，D1），**刻意保留，不该改**。
  # 代价落在这里：上面那条 git add -A 看不见它们下面的东西，不补这一步，首次提交
  # 会**静默**少掉四个 demo 和那个孙项目，而且一声不吭（docs/02-设计决策.md L10）。
  #
  # 🔴 只补「因为 projects/ 这条规则被挡住」的文件，不无脑 git add -f projects：
  #    那样会把各 demo 自己**合法**忽略的东西（__pycache__ / .pytest_cache /
  #    .DS_Store / settings.local.json / cross-edit-allow）一起提进去。
  #    git check-ignore -v 会告诉你每个文件是被哪条规则挡的，只认 pattern 正好是
  #    projects/ 的那些。
  #
  # 🔴 两处 -c core.quotepath=false 不能省：git 默认把非 ASCII 路径转义成
  #    "docs/\351\234\200..." 并加引号，那样的字符串再喂回 git add 会直接
  #    「did not match any files」——本模板的文档名一律是中文，所以这不是边角
  #    情况，是主路径（同一个坑的完整来龙去脉见 docs/02-设计决策.md L1）。
  forced=0
  ignored_list="$(git -c core.quotepath=false ls-files --others --ignored --exclude-standard -- . 2>/dev/null || true)"
  if [ -n "$ignored_list" ]; then
    forced_list="$(printf '%s\n' "$ignored_list" \
      | git -c core.quotepath=false check-ignore -v --stdin 2>/dev/null \
      | awk -F'\t' '{ n = split($1, f, ":"); if (f[n] == "projects/") print $2 }')"
    if [ -n "$forced_list" ]; then
      printf '%s\n' "$forced_list" | tr '\n' '\0' | xargs -0 git add -f -- \
        || { echo "🔴 失败：给展品补 git add -f 没成功" >&2; exit 1; }
      forced="$(printf '%s\n' "$forced_list" | grep -c '')"
    fi
  fi

  # ---- 断言：磁盘上的每个项目单元都真的进了索引 ---------------------------
  # 上面那步要是没生效，后果是「少提交了半棵树」而不是报错——本体系认定最贵的
  # 那类故障。所以提交之前把它数出来：单元的标志是 CLAUDE.md，一个都不许漏。
  missing=""
  while IFS= read -r c; do
    [ -z "$c" ] && continue
    git ls-files --error-unmatch -- "$c" >/dev/null 2>&1 || missing="${missing}${c}
"
  done <<EOF
$(find . -type f -name CLAUDE.md -not -path './.git/*' -not -path './.migration-backup/*' 2>/dev/null | sed 's#^\./##' | sort)
EOF

  if [ -n "$missing" ]; then
    {
      echo "🔴 失败：有项目单元没能进暂存区，首次提交会少掉它们（不继续提交）："
      printf '%s' "$missing" | sed 's/^/     · /'
      echo ""
      echo "   多半是某处 .gitignore 把它们挡住了，而自动补 -f 那一步没覆盖到。"
      echo "   请把这段贴给维护者。"
    } >&2
    exit 1
  fi

  # 首次提交天然过得了提交硬闸：每个单元的 CHANGE-LOG.md 与 README.md 本来就在
  # 暂存区里，而且相对空树整份 CHANGE-LOG 都算新增，记录行净增远大于 0。
  if ! commit_out="$(git commit -q -m "chore: 从模板初始化仓库

分发下来的模板不带 git 历史（源头历史永不随分发，见 docs/03-发布与同步.md §1），
本仓库由 scripts/init-repos.sh 重建，这是它的第一条提交。" 2>&1)"; then
    echo "🔴 失败：首次提交被拒绝。git 的输出：" >&2
    printf '%s\n' "$commit_out" | sed 's/^/     /' >&2
    exit 1
  fi

  echo "✓ 已初始化根仓库：git init（main）+ 提交硬闸已启用 + 首次提交完成"
  if [ "$forced" -gt 0 ]; then
    echo "  （其中 $forced 个文件是用 git add -f 补进来的：模具自己的 .gitignore"
    echo "    排除 projects/，那是它的出厂形态，见 docs/03-发布与同步.md §3.3）"
  fi
fi

cat <<'TIP'

———— 结果 ————
根仓库一个，已就绪。（本模板仓库是单一仓库，没有别的仓库要还原，见 docs/02-设计决策.md D11）

接下来做什么：
  1. 复制模具开自己的项目 —— 见 docs/01-使用指南.md §4
     （模具在 projects/main-sub-architecture-project-demo/）
     🔴 你建出来的项目是「独立嵌套仓库」形态：它自己 git init，它的子项目也各自
        git init。本仓库自己是单一仓库这件事**不传染**给你的项目。
  2. 想验证提交硬闸真的在管事，随便改个文件不带日志提交一次，应当被拒绝：
       echo x >> README.md && git add README.md && git commit -m test    # 应当被拒
     硬闸按**项目单元**判定：动了模具下面的文件，它要的是**模具自己的**
     CHANGE-LOG.md 多一行，拿仓库根的日志顶包不算数。
  3. 在任何项目目录里开 Claude 会话，确立仪式会自动来找你。
TIP
