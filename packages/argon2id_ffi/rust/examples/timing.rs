//! Rust 侧计时器：N 次取中位，输出 ms。务必 `cargo run --release` 跑（debug 下纯 Rust
//! argon2 会慢一个数量级）。与 `scripts/bench_compare.py`（C/argon2-cffi）配对，
//! 同参数、同 N、同「N 次取中位」口径，做同机 C-vs-Rust 对照。

use std::time::Instant;

use argon2id_ffi::api::crypto::argon2id_derive_key;

fn main() {
    let password = b"correct horse battery staple".to_vec();
    let salt = vec![0x02u8; 16];

    // (m_cost KiB, t_cost, parallelism, 标签)
    let runs = [
        (65536u32, 3u32, 1u32, "v0_64MiB_t3_p1"),
        (32768, 4, 1, "fallback_32MiB_t4_p1"),
        (19456, 2, 1, "owasp_19MiB_t2_p1"),
    ];
    const N: usize = 11;

    // 预热（触发分配器/缓存）
    let _ = argon2id_derive_key(password.clone(), salt.clone(), 65536, 3, 1, 32).unwrap();

    println!("impl=rust (RustCrypto argon2 0.5.3, no-SIMD)  N={N}  profile=release/opt-level=3");
    for (m, t, p, label) in runs {
        let mut times = Vec::with_capacity(N);
        for _ in 0..N {
            let t0 = Instant::now();
            let _ = argon2id_derive_key(password.clone(), salt.clone(), m, t, p, 32).unwrap();
            times.push(t0.elapsed().as_secs_f64() * 1000.0);
        }
        times.sort_by(|a, b| a.partial_cmp(b).unwrap());
        println!(
            "{label:24}  median={:8.1}ms  min={:8.1}ms  max={:8.1}ms",
            times[N / 2],
            times[0],
            times[N - 1]
        );
    }
}
