#!/usr/bin/env python3
"""同机 C-vs-Rust Argon2id 对照——C 侧基准。

argon2-cffi 底层封装的是 P-H-C 官方 Argon2 C 参考实现（libargon2），与 dargon2
移动端所用同源。本脚本与 `cargo run --release --example timing`（Rust 侧）配对：
同参数、同 N、同「N 次取中位」口径，量出同一台机器上 C 与 Rust 的 Argon2id 耗时差。

用法：
    pip install argon2-cffi        # 或用项目临时 venv
    python3 scripts/bench_compare.py
"""

import time
from importlib.metadata import version

from argon2.low_level import Type, hash_secret_raw

PASSWORD = b"correct horse battery staple"
SALT = bytes([0x02]) * 16

# (m_cost KiB, t_cost, parallelism, 标签) —— 与 examples/timing.rs 完全一致
RUNS = [
    (65536, 3, 1, "v0_64MiB_t3_p1"),
    (32768, 4, 1, "fallback_32MiB_t4_p1"),
    (19456, 2, 1, "owasp_19MiB_t2_p1"),
]
N = 11


def bench(m, t, p):
    # 预热
    hash_secret_raw(PASSWORD, SALT, time_cost=t, memory_cost=m,
                    parallelism=p, hash_len=32, type=Type.ID, version=0x13)
    xs = []
    for _ in range(N):
        t0 = time.perf_counter()
        hash_secret_raw(PASSWORD, SALT, time_cost=t, memory_cost=m,
                        parallelism=p, hash_len=32, type=Type.ID, version=0x13)
        xs.append((time.perf_counter() - t0) * 1000.0)
    xs.sort()
    return xs


def main():
    print(f"impl=C (argon2-cffi {version('argon2-cffi')} / P-H-C libargon2)  N={N}")
    for m, t, p, label in RUNS:
        xs = bench(m, t, p)
        print(f"{label:24}  median={xs[N // 2]:8.1f}ms  "
              f"min={xs[0]:8.1f}ms  max={xs[-1]:8.1f}ms")


if __name__ == "__main__":
    main()
