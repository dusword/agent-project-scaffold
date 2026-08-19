"""换算逻辑。

这一层是**纯函数**：输入数值和两个单位，输出数值。
不读命令行、不打印、不退出进程 —— 那些是 cli.py 的事。

这么分的理由：纯函数好测（tests/test_converter.py 不用起进程），
而且以后要加个 HTTP 接口或者给 agent 调用时，直接复用这一层就行。
"""

from __future__ import annotations

from .units import LINEAR_UNITS, UnknownUnitError, find_dimension


class DimensionMismatchError(ValueError):
    """两个单位属于不同量纲，换算无意义（比如把千克换算成米）。"""

    def __init__(self, source: str, target: str) -> None:
        super().__init__(f"{source} 与 {target} 不是同一量纲")
        self.source = source
        self.target = target


def _to_celsius(value: float, unit: str) -> float:
    if unit == "c":
        return value
    if unit == "f":
        return (value - 32.0) * 5.0 / 9.0
    if unit == "k":
        return value - 273.15
    raise UnknownUnitError(unit)


def _from_celsius(celsius: float, unit: str) -> float:
    if unit == "c":
        return celsius
    if unit == "f":
        return celsius * 9.0 / 5.0 + 32.0
    if unit == "k":
        return celsius + 273.15
    raise UnknownUnitError(unit)


def convert(value: float, source: str, target: str) -> float:
    """把 value 从 source 单位换算成 target 单位。

    抛 UnknownUnitError（单位不认识）或 DimensionMismatchError（量纲对不上）。
    刻意不吞异常：调用方比这一层更清楚该怎么向用户交代。
    """
    src = source.strip().lower()
    dst = target.strip().lower()

    src_dim = find_dimension(src)
    dst_dim = find_dimension(dst)
    if src_dim != dst_dim:
        raise DimensionMismatchError(source, target)

    if src_dim == "temperature":
        return _from_celsius(_to_celsius(value, src), dst)

    table = LINEAR_UNITS[src_dim]
    return value * table[src] / table[dst]
