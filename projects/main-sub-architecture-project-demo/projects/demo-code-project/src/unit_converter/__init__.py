"""unit_converter —— 一个最小但完整的单位换算器。

模块划分（这就是本 demo 想示范的东西：不要把什么都堆进一个文件）：

    units.py      事实层：有哪些单位、换算系数是多少
    converter.py  逻辑层：纯函数，输入数值出数值，不碰 IO
    cli.py        交互层：解析参数、翻译错误、决定退出码

依赖方向是单向的 cli → converter → units，反向不许引用。
"""

from .converter import DimensionMismatchError, convert
from .units import UnknownUnitError, all_units

__all__ = ["convert", "all_units", "UnknownUnitError", "DimensionMismatchError"]
__version__ = "0.2.0"
