"""cli.py 的测试：退出码对不对、错误信息说不说人话。

只测 main(argv) 这个函数，不起子进程 —— 这也是 cli.main 返回退出码
而不是直接 sys.exit 的原因。
"""

import pytest

from unit_converter.cli import main


class TestHappyPath:
    def test_正常换算返回0并打印结果(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["1", "km", "m"]) == 0
        assert capsys.readouterr().out.strip() == "1000.0 m"

    def test_digits_控制小数位(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["1", "mile", "km", "--digits", "2"]) == 0
        assert capsys.readouterr().out.strip() == "1.61 km"

    def test_list_列出全部单位(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["--list"]) == 0
        out = capsys.readouterr().out
        assert "length:" in out
        assert "temperature:" in out


class TestUserErrors:
    def test_数值不是数字返回1(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["abc", "km", "m"]) == 1
        assert "不是一个数字" in capsys.readouterr().err

    def test_单位不认识返回1并提示_list(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["1", "km", "光年"]) == 1
        err = capsys.readouterr().err
        assert "不认识的单位" in err
        assert "--list" in err

    def test_量纲对不上返回1(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["1", "kg", "m"]) == 1
        assert "同一量纲" in capsys.readouterr().err

    def test_参数不全返回1(self, capsys: pytest.CaptureFixture[str]) -> None:
        assert main(["1", "km"]) == 1
        assert "需要三个参数" in capsys.readouterr().err
