# demo-code-project · 单位换算器

> **类型：代码项目**（交付物 = 能跑起来的东西）。
> 这个项目有双重身份：① 一个真的能用的单位换算 CLI；② **「代码项目」范式的可复制样板**。
>
> **为什么存在**：因为需要一个**真能跑、真有测试**的代码项目样板——
> 空骨架说不清「测试是提交准入」「退出码属于需求」长什么样，所以挑了单位换算这件足够小、
> 又刚好有量纲边界与错误分支的事来承载。
>

> 🔴 **刚接手的 AI agent**：读完本文去读项目根的 `CLAUDE.md`，再读 `docs/01-需求.md` 的「边界」一节。

---

## 是什么

命令行单位换算器，支持三个量纲：

| 量纲 | 单位 |
|---|---|
| 长度 | mm · cm · m · km · inch · foot · mile |
| 重量 | g · kg · ton · oz · lb |
| 温度 | c（摄氏）· f（华氏）· k（开尔文） |

无第三方依赖，只需要 Python ≥ 3.10。

---

## 怎么装

不装也能用（见下面「怎么跑」的免安装方式）。要装成命令的话：

```bash
python3 -m pip install -e .
```

装完就有 `convert` 命令。

---

## 怎么跑

```bash
# 免安装方式（推荐先用这个验证）
PYTHONPATH=src python3 -m unit_converter.cli 1 mile km
PYTHONPATH=src python3 -m unit_converter.cli 100 c f
PYTHONPATH=src python3 -m unit_converter.cli --list

# 装过之后
convert 1 mile km
convert 1 mile km --digits 2
```

### 该看到什么

| 命令 | 输出 | 退出码 |
|---|---|---|
| `convert 1 mile km` | `1.6093 km` | 0 |
| `convert 100 c f` | `212.0 f` | 0 |
| `convert 1 mile km --digits 2` | `1.61 km` | 0 |
| `convert 1 kg m` | `错误：kg 与 m 不是同一量纲。同一量纲之间才能换算。`（stderr） | 1 |
| `convert 1 km 光年` | `错误：不认识的单位 '光年'。用 --list 看支持哪些。`（stderr） | 1 |
| `convert abc km m` | `错误：'abc' 不是一个数字`（stderr） | 1 |

🔴 **退出码是需求的一部分**（要被 shell 脚本判断），不是实现细节。

---

## 怎么测

```bash
python3 -m pytest
```

期望：**39 passed**。测试覆盖正常路径 / 边界 / 错误处理 / CLI 退出码契约四类。

`pyproject.toml` 里配了 `pythonpath = ["src"]`，所以**不装包也能直接跑测试**。

---

## 内容索引

| 路径 | 是什么 |
|---|---|
| `src/unit_converter/units.py` | 事实层：有哪些单位、换算系数是多少。**只有数据和查表** |
| `src/unit_converter/converter.py` | 逻辑层：纯函数，输入数值出数值。**一行 print 都没有** |
| `src/unit_converter/cli.py` | 交互层：解析参数、翻译错误、决定退出码。**唯一碰 IO 的地方** |
| `tests/test_units.py` | 换算表自身的不变量（每个量纲恰好一个基准单位、系数为正、键全小写） |
| `tests/test_converter.py` | 换算逻辑：常见换算 / 往返还原 / 温度交点 / 三类异常 |
| `tests/test_cli.py` | CLI 契约：退出码、错误信息措辞、`--list` 与 `--digits` |
| `pyproject.toml` | 打包配置 + pytest 配置 |
| `docs/01-需求.md` | 🔴 目标 / 功能清单 / **边界（明确不做的事）** / 未决问题 |
| `docs/02-设计.md` | 为什么是三层单向依赖、温度为什么单独写、异常为什么抛到上层 |
| `CHANGE-LOG.md` | 本项目的历史（一条记录 = 一次提交） |
| `CLAUDE.md` | 项目宪法（**在项目根，不在 `.claude/` 里**）：代码项目范式五条 |
| `.claude/` | 规矩 / 钩子 / 确立状态（`rules/` · `hooks/` · `settings.json` · `HARNESS-STATUS.md`） |

依赖方向严格单向：`cli.py → converter.py → units.py`，**反向引用禁止**。

---

## 启用钩子（clone 后第一件事）

```bash
git config core.hooksPath .githooks
git config --get core.hooksPath        # 应输出 .githooks
```

忘了这步，提交硬闸静默失效。

---

## 当前状态

三个量纲全部可用，39 个测试全绿，需求与设计文档齐备。**可以直接复制改名当新代码项目的起点。**
