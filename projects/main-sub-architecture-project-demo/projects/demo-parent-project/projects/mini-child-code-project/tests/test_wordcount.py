"""wordcount 的测试。小项目也要有测试——测试是提交准入，不看项目大小。"""

import pytest

from wordcount import count_words, tokenize


class TestTokenize:
    def test_转小写(self) -> None:
        assert tokenize("The THE the") == ["the", "the", "the"]

    def test_去标点(self) -> None:
        assert tokenize("hello, world! hello.") == ["hello", "world", "hello"]

    def test_保留撇号(self) -> None:
        assert tokenize("don't stop") == ["don't", "stop"]

    def test_保留数字(self) -> None:
        assert tokenize("room 101 and 101") == ["room", "101", "and", "101"]

    def test_空串(self) -> None:
        assert tokenize("") == []


class TestCountWords:
    def test_按频次降序(self) -> None:
        assert count_words("a a a b b c", top=3) == [("a", 3), ("b", 2), ("c", 1)]

    def test_同频次按字母序_结果稳定(self) -> None:
        # 这条是防偶发失败的：Counter.most_common 对同频次顺序不做保证
        assert count_words("pear apple", top=2) == [("apple", 1), ("pear", 1)]

    def test_top_截断(self) -> None:
        assert count_words("a a b b c c", top=2) == [("a", 2), ("b", 2)]

    def test_top_大于词数时返回全部(self) -> None:
        assert count_words("solo", top=10) == [("solo", 1)]

    @pytest.mark.parametrize("text", ["", "   ", "!!! ???"])
    def test_没有词时返回空表(self, text: str) -> None:
        assert count_words(text) == []
