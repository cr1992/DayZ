//! Argon2id / HKDF 基准。`cargo bench` 运行。
//!
//! 关注 v0 参数（m=64MiB, t=3, p=1, len=32）的单次中位耗时——对应 NF1（<1.5s）
//! 与 key-management T3 实测 dargon2 的 498ms 基线做对照。
//! 同机 C-vs-Rust 对照另见 `scripts/compare_argon2.py`（用 argon2-cffi，
//! 底层即 dargon2 所用的 P-H-C C 实现）。

use std::time::Duration;

use criterion::{criterion_group, criterion_main, BenchmarkId, Criterion};
use argon2id_ffi::api::crypto::{argon2id_derive_key, hkdf_sha256_derive_key};

fn bench_argon2id(c: &mut Criterion) {
    let password = b"correct horse battery staple".to_vec();
    let salt = vec![0x02u8; 16];

    let mut group = c.benchmark_group("argon2id");
    group.sample_size(10);
    group.warm_up_time(Duration::from_secs(1));
    group.measurement_time(Duration::from_secs(12));

    // (m_cost KiB, t_cost, parallelism, 标签)
    let params = [
        (65536u32, 3u32, 1u32, "v0_64MiB_t3_p1"), // v0 正式参数
        (32768, 4, 1, "fallback_32MiB_t4_p1"),    // 低端机回退参数
        (19456, 2, 1, "owasp_19MiB_t2_p1"),       // OWASP 下限
    ];
    for (m, t, p, label) in params {
        group.bench_function(BenchmarkId::from_parameter(label), |b| {
            b.iter(|| argon2id_derive_key(password.clone(), salt.clone(), m, t, p, 32).unwrap());
        });
    }
    group.finish();
}

fn bench_hkdf(c: &mut Criterion) {
    let ikm = vec![0x0bu8; 32];
    let salt = vec![0x00u8; 16];
    let info = b"dayz/media/v1".to_vec();

    c.bench_function("hkdf_sha256_expand_32B", |b| {
        b.iter(|| {
            hkdf_sha256_derive_key(ikm.clone(), Some(salt.clone()), info.clone(), 32).unwrap()
        });
    });
}

criterion_group!(benches, bench_argon2id, bench_hkdf);
criterion_main!(benches);
