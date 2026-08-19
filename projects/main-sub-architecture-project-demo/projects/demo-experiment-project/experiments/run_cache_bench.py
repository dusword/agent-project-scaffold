#!/usr/bin/env python3
"""缓存策略对照实验：LRU vs LFU。

用途：拿一段请求轨迹（CSV）喂给两种淘汰策略，比较命中率。

    python3 experiments/run_cache_bench.py --capacity 64
    python3 experiments/run_cache_bench.py --capacity 64 --phase steady
    python3 experiments/run_cache_bench.py --sweep 16,32,64,128,256

🔴 实验项目纪律：本脚本**不改** EXPERIMENTS.md，也不写任何结论。
   它只吐数字，判定由人做完写进 EXPERIMENTS.md。
   理由：让脚本自己写结论，等于让被测者给自己打分。

只用标准库，没有第三方依赖。
"""

from __future__ import annotations

import argparse
import csv
import pathlib
from collections import OrderedDict
from collections.abc import Iterable

DATA_DEFAULT = pathlib.Path(__file__).parent / "data" / "sample-requests.csv"


# ---------------------------------------------------------------- 两种策略
class LRUCache:
    """最近最少使用：淘汰最久没被访问的。"""

    name = "LRU"

    def __init__(self, capacity: int) -> None:
        self.capacity = capacity
        self._store: OrderedDict[str, int] = OrderedDict()

    def access(self, key: str) -> bool:
        """访问一个 key，返回是否命中。"""
        if key in self._store:
            self._store.move_to_end(key)
            return True
        if len(self._store) >= self.capacity:
            self._store.popitem(last=False)  # 淘汰最旧的
        self._store[key] = 1
        return False


class LFUCache:
    """最不经常使用：淘汰访问次数最少的（同次数时淘汰更早进来的）。"""

    name = "LFU"

    def __init__(self, capacity: int) -> None:
        self.capacity = capacity
        self._freq: dict[str, int] = {}
        self._seq: dict[str, int] = {}  # 进入顺序，用于同频次时打破平局
        self._tick = 0

    def access(self, key: str) -> bool:
        self._tick += 1
        if key in self._freq:
            self._freq[key] += 1
            return True
        if len(self._freq) >= self.capacity:
            victim = min(self._freq, key=lambda k: (self._freq[k], self._seq[k]))
            del self._freq[victim]
            del self._seq[victim]
        self._freq[key] = 1
        self._seq[key] = self._tick
        return False


STRATEGIES = (LRUCache, LFUCache)


# ---------------------------------------------------------------- 跑一轮
def load_trace(path: pathlib.Path, phase: str | None) -> list[str]:
    """读轨迹 CSV。phase 为 None 表示全量。"""
    keys: list[str] = []
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if phase and row["phase"] != phase:
                continue
            keys.append(row["key"])
    return keys


def measure(strategy_cls: type, capacity: int, trace: Iterable[str]) -> dict[str, float]:
    cache = strategy_cls(capacity)
    hits = total = 0
    for key in trace:
        total += 1
        if cache.access(key):
            hits += 1
    return {
        "strategy": cache.name,
        "capacity": capacity,
        "requests": total,
        "hits": hits,
        "hit_rate": (hits / total * 100) if total else 0.0,
    }


def print_table(rows: list[dict[str, float]]) -> None:
    print(f"{'策略':<6}{'容量':>6}{'请求数':>9}{'命中数':>9}{'命中率':>10}")
    print("-" * 42)
    for r in rows:
        print(
            f"{r['strategy']:<6}{r['capacity']:>6}{r['requests']:>9}"
            f"{r['hits']:>9}{r['hit_rate']:>9.2f}%"
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="LRU vs LFU 命中率对照")
    parser.add_argument("--data", type=pathlib.Path, default=DATA_DEFAULT)
    parser.add_argument("--capacity", type=int, default=64)
    parser.add_argument(
        "--phase",
        choices=["steady", "scan"],
        default=None,
        help="只跑某个阶段的轨迹；不给就是全量",
    )
    parser.add_argument(
        "--sweep", default=None, help="逗号分隔的容量列表，例如 16,32,64,128"
    )
    args = parser.parse_args(argv)

    if not args.data.exists():
        print(f"错误：找不到轨迹文件 {args.data}")
        return 1

    trace = load_trace(args.data, args.phase)
    if not trace:
        print(f"错误：轨迹为空（phase={args.phase}）")
        return 1

    capacities = (
        [int(c) for c in args.sweep.split(",")] if args.sweep else [args.capacity]
    )

    label = args.phase or "全量"
    print(f"轨迹：{args.data.name}  阶段：{label}  请求数：{len(trace)}  唯一 key：{len(set(trace))}")
    print()

    rows = [
        measure(cls, cap, trace) for cap in capacities for cls in STRATEGIES
    ]
    print_table(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
