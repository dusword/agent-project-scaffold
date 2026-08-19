# mini-child-code-project · 极简词频统计

> **类型：代码项目** · **层级：孙项目**（在 `demo-parent-project/projects/` 下）
>
> 🔴 **为什么存在**：不是为了这段代码，而是**由上一级父项目为示范嵌套结构而建**——
> 它要证明「任意层级都能继续嵌套一个完整项目」：自己 `git init` 过、有自己的宪法、
> 自己的提交硬闸，和上层是**同一套骨架**，只是更小。

---

## 怎么跑

```bash
echo "the quick brown fox jumps over the lazy dog the fox" | python3 src/wordcount.py 3
```

## 该看到什么

```
     3  the
     2  fox
     1  brown
```

（第三行是 `brown` 而不是 `dog` / `jumps`：同频次按**字母序**排，保证结果稳定可测。）

空输入时打提示到 stderr 并返回退出码 1。

## 怎么测

```bash
python3 -m pytest
```

期望：**12 passed**。

---

## 内容索引

| 路径 | 是什么 |
|---|---|
| `src/wordcount.py` | 切词 + 计数 + CLI，全部在这一个文件里（项目太小，分层反而是负担） |
| `tests/test_wordcount.py` | 12 个测试：切词 5 个 + 计数 7 个（含同频次稳定性、空输入边界） |
| `pyproject.toml` | pytest 配置（`pythonpath = ["src"]`，不装包也能测） |
| `CLAUDE.md` | 项目宪法（**在项目根**）：精简版代码项目范式 + 🔴 不许改父项目的东西 |
| `CHANGE-LOG.md` | 本项目的历史 |
| `.claude/` | 规矩 / 钩子 / 确立状态 |

---

## 🔴 为什么这里没有分层，而 demo-code-project 有

`demo-code-project` 分了三层（cli / converter / units），这里全在一个文件。
**这不是不一致，是刻意的**：

| | demo-code-project | 本项目 |
|---|---|---|
| 数据表 | 会持续增加单位 | 词表不存在，不会变 |
| 复用需求 | 以后要给 HTTP / agent 调 | 没有 |
| 分层收益 | 高（加单位只改一张字典） | 低 |
| 分层代价 | 可接受 | **三个文件放三个函数，纯负担** |

**范式给的是判据，不是模板。** 照抄结构而不看收益，是把规矩用坏的最常见方式。

---

## 启用钩子（clone 后第一件事）

```bash
git config core.hooksPath .githooks
git config --get core.hooksPath        # 应输出 .githooks
```
