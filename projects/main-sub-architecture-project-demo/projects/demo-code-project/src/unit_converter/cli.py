"""命令行入口。

这一层**只负责人机交互**：解析参数、把异常翻译成人话、决定退出码。
所有换算逻辑都在 converter.py，这里一行数学都不写。

退出码约定（写在这里，README 里也要写一遍）：
    0  换算成功
    1  用户输入有问题（单位不认识 / 量纲对不上 / 数值不是数字）
    2  参数用法错误（由 argparse 自己产生）
"""

from __future__ import annotations

import argparse
import sys
from collections.abc import Sequence

from .converter import DimensionMismatchError, convert
from .units import UnknownUnitError, all_units


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="convert",
        description="单位换算器：长度 / 重量 / 温度",
    )
    parser.add_argument("value", nargs="?", help="要换算的数值")
    parser.add_argument("source", nargs="?", help="源单位，例如 km")
    parser.add_argument("target", nargs="?", help="目标单位，例如 mile")
    parser.add_argument(
        "--list", action="store_true", help="列出全部支持的单位后退出"
    )
    parser.add_argument(
        "--digits", type=int, default=4, help="结果保留几位小数（默认 4）"
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """真正的入口。返回退出码而不是直接 sys.exit —— 这样测试可以直接调它。"""
    parser = _build_parser()
    args = parser.parse_args(argv)

    if args.list:
        for dimension, units in all_units().items():
            print(f"{dimension}: {', '.join(units)}")
        return 0

    if args.value is None or args.source is None or args.target is None:
        parser.print_usage(sys.stderr)
        print("错误：需要三个参数 —— 数值 源单位 目标单位", file=sys.stderr)
        return 1

    try:
        value = float(args.value)
    except ValueError:
        print(f"错误：'{args.value}' 不是一个数字", file=sys.stderr)
        return 1

    try:
        result = convert(value, args.source, args.target)
    except DimensionMismatchError as exc:
        print(f"错误：{exc}。同一量纲之间才能换算。", file=sys.stderr)
        return 1
    except UnknownUnitError as exc:
        print(f"错误：不认识的单位 '{exc.args[0]}'。用 --list 看支持哪些。", file=sys.stderr)
        return 1

    print(f"{round(result, args.digits)} {args.target.strip().lower()}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
