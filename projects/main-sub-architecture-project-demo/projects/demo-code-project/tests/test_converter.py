"""converter.py 的测试：正常路径 + 边界 + 错误处理。"""

import pytest

from unit_converter.converter import DimensionMismatchError, convert
from unit_converter.units import UnknownUnitError


class TestLinear:
    @pytest.mark.parametrize(
        ("value", "src", "dst", "expected"),
        [
            (1, "km", "m", 1000.0),
            (1000, "m", "km", 1.0),
            (1, "inch", "cm", 2.54),
            (1, "mile", "km", 1.609344),
            (1, "kg", "g", 1000.0),
            (1, "lb", "g", 453.59237),
        ],
    )
    def test_常见换算(self, value: float, src: str, dst: str, expected: float) -> None:
        assert convert(value, src, dst) == pytest.approx(expected)

    def test_同单位换算是恒等的(self) -> None:
        assert convert(42.5, "m", "m") == pytest.approx(42.5)

    def test_来回换算能还原(self) -> None:
        there = convert(7.3, "foot", "mm")
        assert convert(there, "mm", "foot") == pytest.approx(7.3)

    def test_零和负数照常处理(self) -> None:
        # 长度出现负数在业务上少见，但换算本身是纯数学，不该在这一层拦
        assert convert(0, "km", "m") == pytest.approx(0.0)
        assert convert(-2, "km", "m") == pytest.approx(-2000.0)


class TestTemperature:
    @pytest.mark.parametrize(
        ("value", "src", "dst", "expected"),
        [
            (0, "c", "f", 32.0),
            (100, "c", "f", 212.0),
            (-40, "c", "f", -40.0),      # 华氏摄氏唯一的交点
            (0, "c", "k", 273.15),
            (273.15, "k", "c", 0.0),
            (98.6, "f", "c", 37.0),
        ],
    )
    def test_温度换算(self, value: float, src: str, dst: str, expected: float) -> None:
        assert convert(value, src, dst) == pytest.approx(expected)

    def test_绝对零度往返(self) -> None:
        assert convert(0, "k", "c") == pytest.approx(-273.15)
        assert convert(-273.15, "c", "k") == pytest.approx(0.0)


class TestErrors:
    def test_量纲对不上时抛_DimensionMismatchError(self) -> None:
        with pytest.raises(DimensionMismatchError) as caught:
            convert(1, "kg", "m")
        assert caught.value.source == "kg"
        assert caught.value.target == "m"

    def test_温度和长度也算量纲对不上(self) -> None:
        with pytest.raises(DimensionMismatchError):
            convert(1, "c", "m")

    def test_未知单位抛_UnknownUnitError(self) -> None:
        with pytest.raises(UnknownUnitError):
            convert(1, "m", "光年")

    def test_大小写与空白不影响结果(self) -> None:
        assert convert(1, "  KM ", "M") == pytest.approx(1000.0)
