# 项目宪法 · mini-child-code-project

> **类型：代码项目**（交付物 = 能跑起来的东西）。
> **层级：孙项目** —— 它在 `demo-parent-project/projects/` 下，而那个又在模板根的 `projects/` 下。
> 规矩细则在 [`.claude/rules/`](.claude/rules/)。冲突时：`.claude/rules/boundary.md` > 本文件 > 其它。

---

## 🔴 新会话第一件事

1. 读本文件
2. 读 [`README.md`](README.md)
3. `git status --short` + `git log --oneline -5`

---

## 这是什么

一个极简词频统计（`src/wordcount.py` + `tests/test_wordcount.py`，就这两个文件）。

**它存在的意义不是这段代码**，是证明一件事：

> 🔴 **任意层级都能继续嵌套一个完整项目。**
> 它自己 `git init` 过、有自己的 `CLAUDE.md`、自己的 `.githooks/pre-commit`、
> 自己的 `HARNESS-STATUS.md`。它和模板根是**同一套骨架**，只是内容更小。

递归性是本体系的核心：一个项目是「父」还是「子」，只取决于它有没有 `projects/` 目录，
不是两种不同的东西。

---

## 代码项目范式（精简版）

| 规矩 | 说明 |
|---|---|
| **测试是提交准入** | 项目再小也要有测试。当前 12 个，跑 `python3 -m pytest` |
| **结果必须稳定可测** | `count_words` 对同频次按字母序排序，就是为了这条——`Counter.most_common` 不保证同频次顺序，直接用会偶发失败 |
| **交付说明必答三问** | 怎么起 / 点哪里 / 该看到什么，见 `README.md` |

---

## 🔴 边界：父项目的东西不归你管

这条在嵌套结构里特别容易犯：

| 想干的事 | 判定 |
|---|---|
| 改 `../../README.md`（父项目的子项目索引表） | ❌ 越界。父项目的索引由在父项目里工作的人维护 |
| 改 `../../CHANGE-LOG.md` | ❌ 越界。**父级日志只记父级** |
| 改本项目任何文件 | ✅ 界内 |

越界由 `.claude/hooks/boundary-guard.sh` 拦截，跨界走 `.claude/rules/boundary.md` §3 的授权流程。

---

## 干活纪律

提交时用 `git add <显式路径>`，**不要用全量形态**（`-A`、`--all`、裸点）。
理由：全量暂存会把你没打算提交的东西一起卷进来，而本体系每次提交都要在
CHANGE-LOG 里对应一条记录——卷进来的东西没法写进那条记录。

`.githooks/pre-commit` 强制：改任何东西 → `CHANGE-LOG.md` 必须一起暂存。
🔴 日志必须**真的新增一行记录**——把本次说明改写进上一条记录那一行不算，闸门会拒。
启用钩子（clone 后一次）：`git config core.hooksPath .githooks`
