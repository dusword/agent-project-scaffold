# main-sub-architecture-project-demo · 一个演示用的总项目

我是一个**总项目（父项目）**。我自己不产出业务内容——我产出的是**秩序**：
一份统筹说明、一张子项目索引表、一套所有子项目共用的规矩与钩子。

我下面挂着四个**类型完全不同**的子项目：一个代码项目、一个实验项目、一个文档仓库，
以及一个自己又往下嵌了一层的父项目。它们彼此没有业务关联——这是刻意的，
它们合在一起要演示的是：**同一套骨架能装下四种性质完全不同的工作。**

**我为什么存在**：因为「同一套骨架装得下四种性质完全不同的工作、而且能一层层往下嵌」这件事
光用文字说不清，得有一棵真的树摆在这儿——我就是那棵树。
**我这个形状为什么是父子树**：目录树就是**任务拆解树**，大任务拆小、小任务再拆；
调研会不断催生尝试性方向，每个方向开一个子项目去试，**试不通也留档不删**（见 [`CLAUDE.md`](CLAUDE.md)）。

**想维护我**：改我自己的规矩、统筹文档、索引表，都在这里做。
但**子项目是独立的 git 仓库**，要改它们请去它们各自的目录开会话——在这里改属于越界。

⚠️ **这个方向钩子拦不住**：子项目物理上就在我这棵树**内**（`projects/<子项目>/`），
而 `boundary-guard.sh` 按「目标是否在本项目树内」判定，所以在这里改子项目**机器上一律放行**。
**正因为没有机器兜底，这条更要自己守住。** 兜底只剩两道，都是事后的：子项目自己的 `pre-commit`
会要求你补**它自己的** CHANGE-LOG；以及子项目独立的 git 历史让这次改动事后可审计。
详见 [`.claude/rules/boundary.md`](.claude/rules/boundary.md) §4 局限表。

---

## 内容索引

| 路径 | 是什么 |
|---|---|
| `CLAUDE.md` | 项目宪法（**在项目根，不在 `.claude/` 里**）：父项目范式、git 约定、干活纪律、新建子项目七步 |
| `README.md` | 本文。目录指引 + 子项目索引 |
| `CHANGE-LOG.md` | 本项目自己的历史。🔴 **只记父级的事，子项目的变化不往上冒泡** |
| `docs/00-项目说明.md` | 🔴 统筹说明：这里在管什么 / 为什么按类型拆 / 依赖与顺序 / 父项目自己的边界 / 什么时候该拆新子项目 |
| `.claude/HARNESS-STATUS.md` | harness 确立状态。**记录的项目名 ≠ 目录名就会触发确立仪式** |
| `.claude/rules/boundary.md` | 项目边界：只写自己这棵树 + 跨项目授权流程 |
| `.claude/rules/docs-discipline.md` | 文档纪律：README 是接口，CHANGE-LOG 是历史 |
| `.claude/rules/harness-setup.md` | 确立仪式的操作手册 |
| `.claude/hooks/boundary-guard.sh` | 越界拦截钩子（PreToolUse / `Write\|Edit`，越界 exit 2） |
| `.claude/hooks/harness-check.sh` | 确立仪式触发器（SessionStart，往上下文注入指令） |
| `.claude/settings.json` | 把上面两个钩子挂到 Claude Code 上 |
| `.githooks/pre-commit` | 提交硬闸：改动必留日志（且日志必须**真的新增一条记录**）、结构变化必更 README |
| `.gitignore` | 排除 `projects/`（独立嵌套仓库）、放行条、本机私有设置 |
| `projects/` | 子项目目录，**整个被 `.gitignore` 排除**（每个子项目是独立 git 仓库） |

---

## 子项目索引

每个子项目都是**完整独立的 git 仓库**，有自己的宪法、CHANGE-LOG 和提交硬闸。
下面的「怎么跑」都要**先 `cd` 进那个目录**。

| 子项目 | 类型 | 是什么（含来由） | 状态 | 怎么跑 |
|---|---|---|---|---|
| [`projects/demo-code-project`](projects/demo-code-project) | 代码项目 | 命令行单位换算器，支持长度 / 重量 / 温度，退出码是需求的一部分。39 个测试全绿。**因需要一个「代码项目」的可运行样板而建**——光有空骨架说不清「测试是提交准入」长什么样 | ✅ 已完成 | `PYTHONPATH=src python3 -m unit_converter.cli 1 mile km`<br>测试：`python3 -m pytest`（期望 39 passed） |
| [`projects/demo-experiment-project`](projects/demo-experiment-project) | 实验项目 | 验证缓存淘汰策略选 LRU 还是 LFU，两轮实验含一条**负面结论**。**因某查询服务高峰期变慢、要先定策略再动手而建** | 🚧 进行中（结论被一条待决策挡住，未定稿） | `python3 experiments/run_cache_bench.py --capacity 64 --phase steady`<br>结论看 `docs/04-结论与方案.md` |
| [`projects/demo-docs-project`](projects/demo-docs-project) | 文档仓库 | 业务规则与调研笔记，`inbox/` 收原始材料、`archive/` 放已归档的。archive 2 份 / inbox 2 份。**因规则与笔记散在聊天记录里、没人敢引用而建** | 🚧 进行中（知识持续沉淀，没有「做完」这一天） | 没有可执行的东西，**读 `README.md` 的索引表**即可 |
| [`projects/demo-parent-project`](projects/demo-parent-project) | 父项目 | 统筹「把散落的定时任务收拢」，**自己下面又挂着一个孙项目**。**因那件事要拆成三种性质不同的子项目、需要先有人管秩序而建** | 🚧 进行中（三个真实子项目待建） | `cd projects/mini-child-code-project && python3 -m pytest`（期望 12 passed） |

🔴 **「状态」列答的是生命周期**，只有四个取值：**🚧 进行中 · ⏸ 暂停 · ✅ 已完成 · 🗄 已放弃（留档）**。
能不能跑、几个测试绿这类运行情况写进「是什么」列，那一列同时要带上**来由**（因什么而建）。

🔴 **放弃的子项目不删目录、不移出 `projects/`**——只把状态改成 🗄，并在它自己的 README 顶部写
「放弃说明」（为什么停 / 验证到哪 / 若重启从哪接）。**「决定不做」本身是信息**，
删掉档案等于这次尝试没发生过。规矩见 [`CLAUDE.md`](CLAUDE.md)「子项目的退场」。

四个子项目为什么这么摆、什么时候该拆新的，见 [`docs/00-项目说明.md`](docs/00-项目说明.md)。

### 🔴 关于 `projects/` 的两件事

1. **它整个被本仓库 `.gitignore` 排除。** 每个子项目自己 `git init`，是完整独立的仓库。
   所以在这里 `git status` **看不到任何子项目的改动**——这是设计，不是故障。
2. **新建子项目后要手工回来更新上面的索引表**（+ 记一条 CHANGE-LOG）。
   `pre-commit` 规则二本来管这个，但因为 `projects/` 被 ignore，git 看不到那次新增，
   **规则二不会触发。这一步靠纪律。**

---

## 启用钩子（clone 后第一件事）

```bash
git config core.hooksPath .githooks
git config --get core.hooksPath        # 应输出 .githooks
```

🔴 git 不会自动启用仓库内的钩子（安全设计）。**忘了这步，提交硬闸静默失效。**

---

## 当前状态

骨架已立，统筹说明已成文，四个子项目全部收录并建立索引（索引表带生命周期状态：1 个 ✅ 已完成、3 个 🚧 进行中，
暂无 ⏸ 暂停 / 🗄 已放弃）。

各子项目自己的状态见它们的 README：代码项目 39 测试全绿；实验项目两轮做完、结论被一条待决策挡住未定稿；
文档仓库 archive 2 份 / inbox 2 份；父项目下挂一个可跑的孙项目（12 测试全绿）。

---

## 许可与来源

内部项目，示例内容均为中性编造，不含任何真实业务数据。
