"""单位定义与换算表。

这一层**只描述事实**，不做任何计算流程编排：
- 每个量纲（长度 / 重量 / 温度）有哪些单位
- 单位之间怎么换算

拆成独立模块的理由：换算表要被 converter 和测试同时引用，
而且以后新增量纲时，改动应当只落在这个文件里。
"""

from __future__ import annotations

# ---- 线性量纲：全部先换算到「基准单位」，再换算到目标单位 --------------------
# 值 = 该单位相当于多少个基准单位
LINEAR_UNITS: dict[str, dict[str, float]] = {
    "length": {  # 基准：米
        "mm": 0.001,
        "cm": 0.01,
        "m": 1.0,
        "km": 1000.0,
        "inch": 0.0254,
        "foot": 0.3048,
        "mile": 1609.344,
    },
    "weight": {  # 基准：千克
        "g": 0.001,
        "kg": 1.0,
        "ton": 1000.0,
        "oz": 0.028349523125,
        "lb": 0.45359237,
    },
}

# ---- 非线性量纲：温度有偏移量，套不进上面那张表，单独处理 --------------------
TEMPERATURE_UNITS: tuple[str, ...] = ("c", "f", "k")


class UnknownUnitError(ValueError):
    """给出的单位不在任何一张换算表里。"""


def find_dimension(unit: str) -> str:
    """根据单位名反查它属于哪个量纲。

    返回 "length" / "weight" / "temperature"。
    查不到抛 UnknownUnitError —— 调用方负责翻译成给人看的话。
    """
    key = unit.strip().lower()
    if key in TEMPERATURE_UNITS:
        return "temperature"
    for dimension, table in LINEAR_UNITS.items():
        if key in table:
            return dimension
    raise UnknownUnitError(unit)


def all_units() -> dict[str, list[str]]:
    """列出全部支持的单位，按量纲分组。CLI 的 --list 用它。"""
    listing: dict[str, list[str]] = {
        name: sorted(table) for name, table in LINEAR_UNITS.items()
    }
    listing["temperature"] = list(TEMPERATURE_UNITS)
    return listing
