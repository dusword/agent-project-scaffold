"""极简词频统计。

比 demo-code-project 更小：**一个模块 + 一个测试文件**。
它存在的意义不是示范代码组织，而是证明「任意层级都能继续嵌套一个完整项目」——
它自己有独立 git 仓库、自己的 CLAUDE.md、自己的提交硬闸。
"""

from __future__ import annotations

import re
import sys
from collections import Counter

WORD_RE = re.compile(r"[a-z0-9']+")


def tokenize(text: str) -> list[str]:
    """切词：转小写，只保留字母数字和撇号。"""
    return WORD_RE.findall(text.lower())


def count_words(text: str, top: int = 5) -> list[tuple[str, int]]:
    """返回出现次数最多的前 top 个词。

    并列时按字母序，保证结果**稳定可测**——
    Counter.most_common 对同频次的顺序不做保证，直接用它测试会偶发失败。
    """
    counter = Counter(tokenize(text))
    return sorted(counter.items(), key=lambda kv: (-kv[1], kv[0]))[:top]


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else list(argv)
    top = int(args[0]) if args else 5
    text = sys.stdin.read()
    if not text.strip():
        print("错误：标准输入是空的。用法：echo '文本' | python3 src/wordcount.py 3", file=sys.stderr)
        return 1
    for word, times in count_words(text, top):
        print(f"{times:>6}  {word}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
