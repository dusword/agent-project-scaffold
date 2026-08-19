"""units.py 的测试：换算表本身对不对、反查量纲准不准。"""

import pytest

from unit_converter.units import (
    LINEAR_UNITS,
    TEMPERATURE_UNITS,
    UnknownUnitError,
    all_units,
    find_dimension,
)


class TestFindDimension:
    @pytest.mark.parametrize(
        ("unit", "expected"),
        [
            ("m", "length"),
            ("KM", "length"),          # 大小写不敏感
            ("  inch  ", "length"),    # 前后空白要容忍
            ("kg", "weight"),
            ("lb", "weight"),
            ("c", "temperature"),
            ("F", "temperature"),
        ],
    )
    def test_已知单位能反查到量纲(self, unit: str, expected: str) -> None:
        assert find_dimension(unit) == expected

    def test_未知单位抛异常(self) -> None:
        with pytest.raises(UnknownUnitError):
            find_dimension("光年")


class TestTables:
    def test_每个线性量纲都有一个系数为1的基准单位(self) -> None:
        for dimension, table in LINEAR_UNITS.items():
            bases = [u for u, factor in table.items() if factor == 1.0]
            assert len(bases) == 1, f"{dimension} 应当恰好有一个基准单位，实际 {bases}"

    def test_所有系数为正(self) -> None:
        for table in LINEAR_UNITS.values():
            for unit, factor in table.items():
                assert factor > 0, f"{unit} 的系数必须为正"

    def test_单位名一律小写(self) -> None:
        # find_dimension 会把输入转小写去查表，所以表里的键必须已经是小写
        for table in LINEAR_UNITS.values():
            for unit in table:
                assert unit == unit.lower()
        for unit in TEMPERATURE_UNITS:
            assert unit == unit.lower()


def test_all_units_覆盖三个量纲() -> None:
    listing = all_units()
    assert set(listing) == {"length", "weight", "temperature"}
    assert "mile" in listing["length"]
    assert "k" in listing["temperature"]
