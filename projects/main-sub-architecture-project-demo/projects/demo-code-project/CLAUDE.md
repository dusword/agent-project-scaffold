# 项目宪法 · demo-code-project

> **类型：代码项目。交付物 = 能跑起来的东西。**
> 规矩细则在 [`.claude/rules/`](.claude/rules/)。冲突时：`.claude/rules/boundary.md` > 本文件 > 其它。

---

## 🔴 新会话第一件事

1. 读本文件
2. 读 [`README.md`](README.md) —— 是什么 / 怎么装 / 怎么跑 / 怎么测
3. 读 [`docs/01-需求.md`](docs/01-需求.md) —— **尤其是「边界」一节，那是不许做的事**
4. 读 [`docs/02-设计.md`](docs/02-设计.md) —— 为什么是三层单向依赖
5. `git status --short` + `git log --oneline -5`

---

## 这是什么

一个单位换算 CLI（长度 / 重量 / 温度）。同时是**「代码项目」范式的样板**：
以后建新的代码项目，复制本目录改名即可。

```
src/unit_converter/    cli.py → converter.py → units.py（单向依赖，反向禁止）
tests/                 一个源码模块对一个测试文件
docs/                  01-需求.md · 02-设计.md
```

---

## 🔴 代码项目范式

### 1. 测试是提交准入，不是可选项

**没有测试的功能不成立。** 每个功能改动必须同时带上测试，覆盖四类：

| 类 | 例（本项目现有的） |
|---|---|
| 正常路径 | `convert(1, "km", "m") == 1000` |
| 边界 | `-40 c → -40 f`（唯一交点）· 零和负数 · 同单位换算 |
| 错误处理 | 单位不认识 / 量纲对不上 / 数值不是数字 |
| 契约 | CLI 退出码（0 / 1）——退出码是需求的一部分，见 `docs/01-需求.md` §2 |

🔴 **不许为了让测试变绿而弱化断言、跳过测试、或改测试去迎合实现。**
测试挂了说明代码有问题，去修代码。

跑测试（改完必跑，不要凭感觉说「应该没问题」）：

```bash
python3 -m pytest          # 期望：39 passed
```

### 2. 一功能一分支

```
feat/xxx    新功能
fix/xxx     修缺陷
docs/xxx    纯文档
refactor/xxx 重构（不改行为）
test/xxx    补测试
```

分支生命周期短：做完即合即删。不要留着长期分叉。

### 3. 交付说明必答三问

每次交付（提交 / 汇报）都要写清，不要让人自己猜怎么用：

```
## 怎么起
python3 -m pytest && PYTHONPATH=src python3 -m unit_converter.cli --list

## 点哪里
PYTHONPATH=src python3 -m unit_converter.cli 100 c f

## 该看到什么
212.0 f （退出码 0）；换成 `1 kg m` 应报「不是同一量纲」且退出码 1
```

### 4. 改动落在哪一层，先想清楚

| 改什么 | 落在哪 | 反面做法 |
|---|---|---|
| 加一个新单位 | `units.py` 的字典，**只改这一处** | 在 converter 里写 if 特判 |
| 改换算数学 | `converter.py` | 在 cli 里算 |
| 改错误措辞 / 退出码 | `cli.py` | 让 converter 去 print |

🔴 **`converter.py` 里一行 `print` 都不许有**，`units.py` 里一行计算都不许有。
理由见 `docs/02-设计.md` §1。

### 5. 需求边界不许自己扩

`docs/01-需求.md` §3 明确列了**不做**的清单（货币 / 复合量纲 / REPL / GUI / 历史记录）。
想做其中任何一条 → **先回来改需求文档并得到确认**，不要「顺手加一点」。

---

## 干活纪律

### 提交

```
git add <显式路径>     # 🔴 不用 -A / .
git commit
```

`.githooks/pre-commit` 会强制：改任何东西 → `CHANGE-LOG.md` 必须一起暂存；
`docs/` 有新增/删除/改名 → `README.md` 必须一起暂存。
**一条 CHANGE-LOG 记录 = 一次提交。**
🔴 日志必须**真的新增一行记录**——把本次说明改写进上一条记录那一行不算，闸门会拒。

启用钩子（clone 后一次）：`git config core.hooksPath .githooks`

### 边界

只写本项目树内的文件。越界由 `.claude/hooks/boundary-guard.sh` 拦截，
跨界走 `.claude/rules/boundary.md` §3 的授权流程。

### 保持真实

不把未验证的写成已完成；测试挂了就说挂了并附输出；跳过了就说跳过了。
