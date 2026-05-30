//! 密码学算法核心：Argon2id 密钥派生 + HKDF-SHA256 密钥扩展。
//!
//! 纯 Rust 算法层（无 FFI / 无平台依赖），由 `cargo test` 独立覆盖；
//! 对外的 C-ABI 暴露见 `ffi.rs`。底层算法来自 RustCrypto 官方 crate：
//! - Argon2id：`argon2`（开启 `zeroize` feature，内部内存块算完即擦）
//! - HKDF-SHA256：`hkdf` + `sha2`
//!
//! 设计与需求见 `specs/archive/2026-05-30-dayz-security-rust/`。
//!
//! ## 关于内存擦除（R4）的诚实边界
//! 本层只能擦除**进入 Rust 的副本**：FRB 把 Dart 的 `Uint8List` 反序列化成
//! `Vec<u8>` 时已发生一次拷贝，函数返回后我们对该副本调用 `zeroize`。
//! 但 **Dart 侧原始 `Uint8List` 不在本层掌控内**——调用方需自行清零。
//! 派生结果 `out` 需返回给 Dart，无法在本层擦除。

use argon2::{Algorithm, Argon2, Params, Version};
use hkdf::Hkdf;
use sha2::Sha256;
use zeroize::Zeroize;

/// 派生密钥输出长度的允许区间（字节）。下限 16 覆盖常见对称密钥，
/// 上限 1024 防御异常大请求；超出即拒绝（而非静默截断）。
const MIN_OUTPUT_LEN: u32 = 16;
const MAX_OUTPUT_LEN: u32 = 1024;

/// Argon2 规范要求 salt 至少 8 字节。
const MIN_SALT_LEN: usize = 8;

/// HKDF-SHA256 单次最多扩展 255 * HashLen 字节。
const MAX_HKDF_OUTPUT_LEN: u32 = 255 * 32;

/// 用 **Argon2id**（version 0x13）从口令 + salt 派生密钥。
///
/// 确定性：相同 `(password, salt, m_cost, t_cost, parallelism, output_len)`
/// 必得相同输出，可跨设备复算（备份口令派生即依赖此性质）。
///
/// 参数：
/// - `m_cost`：内存代价，单位 **KiB**（例：64 MiB → 65536）。
/// - `t_cost`：迭代次数（时间代价）。
/// - `parallelism`：并行 lane 数。
/// - `output_len`：派生密钥字节数，须落在 `[16, 1024]`。
///
/// 失败时返回人类可读的错误字符串（FRB 会转成 Dart 异常）。
/// 无论成败，函数退出前都会 `zeroize` 传入的 `password` 副本。
pub fn argon2id_derive_key(
    mut password: Vec<u8>,
    salt: Vec<u8>,
    m_cost: u32,
    t_cost: u32,
    parallelism: u32,
    output_len: u32,
) -> Result<Vec<u8>, String> {
    // 用闭包收口，保证后面的 zeroize 一定执行。
    let result = (|| {
        if !(MIN_OUTPUT_LEN..=MAX_OUTPUT_LEN).contains(&output_len) {
            return Err(format!(
                "output_len {output_len} 超出允许范围 [{MIN_OUTPUT_LEN}, {MAX_OUTPUT_LEN}]"
            ));
        }
        if salt.len() < MIN_SALT_LEN {
            return Err(format!(
                "salt 长度 {} < {MIN_SALT_LEN} 字节，不符合 Argon2 规范",
                salt.len()
            ));
        }

        let params = Params::new(m_cost, t_cost, parallelism, Some(output_len as usize))
            .map_err(|e| format!("Argon2 参数非法：{e}"))?;
        let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);

        let mut out = vec![0u8; output_len as usize];
        argon2
            .hash_password_into(&password, &salt, &mut out)
            .map_err(|e| format!("Argon2id 计算失败：{e}"))?;
        Ok(out)
    })();

    password.zeroize();
    result
}

/// 用 **HKDF-SHA256** 从输入密钥材料 `ikm` 扩展出固定长度子密钥。
///
/// 供 key-management 派生设备媒体密钥（`info = "dayz/media/v1"`）等场景使用。
/// `salt` 可为 `None`（HKDF 规范下等价于全零 salt）。
///
/// 函数退出前 `zeroize` 传入的 `ikm` 副本。
pub fn hkdf_sha256_derive_key(
    mut ikm: Vec<u8>,
    salt: Option<Vec<u8>>,
    info: Vec<u8>,
    output_len: u32,
) -> Result<Vec<u8>, String> {
    let result = (|| {
        if output_len == 0 || output_len > MAX_HKDF_OUTPUT_LEN {
            return Err(format!(
                "output_len {output_len} 超出 HKDF-SHA256 允许范围 [1, {MAX_HKDF_OUTPUT_LEN}]"
            ));
        }
        let hk = Hkdf::<Sha256>::new(salt.as_deref(), &ikm);
        let mut okm = vec![0u8; output_len as usize];
        hk.expand(&info, &mut okm)
            .map_err(|e| format!("HKDF 扩展失败：{e}"))?;
        Ok(okm)
    })();

    ikm.zeroize();
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    // ---- Argon2id 已知答案向量（KAT）----
    // 参考实现：argon2-cffi 25.1.0（独立 C 实现），type=Argon2id, version=0x13。
    // 任一字节不符即说明本库与权威实现产生分歧。
    #[test]
    fn argon2id_matches_reference_vectors() {
        struct Kat {
            pwd: &'static [u8],
            salt: &'static [u8],
            t: u32,
            m: u32,
            p: u32,
            len: u32,
            hex: &'static str,
        }
        let kats = [
            Kat { pwd: b"password", salt: b"somesalt12345678", t: 2, m: 256, p: 1, len: 32,
                  hex: "8110e1165eb0e1114ee37d5ff017573ba0084b8366b4108db44749954b8d9871" },
            Kat { pwd: b"password", salt: b"somesalt12345678", t: 3, m: 512, p: 2, len: 32,
                  hex: "2bc785154e5a2d1dda9fb07d4589b77ce64c022df6c63e373b31c9f3bc0b30f8" },
            Kat { pwd: b"", salt: b"0000000000000000", t: 1, m: 64, p: 1, len: 16,
                  hex: "96beeae372717ec8abdc8741e3400b33" },
            Kat { pwd: b"correct horse", salt: b"NaCl-with-8b", t: 3, m: 1024, p: 1, len: 64,
                  hex: "95750f2e33061e857673731eab5453a587fefeb398ff8d6373a84bcaf0e0d63000840c72a6a0a3004c59dc1ff7e0d98579938954405cb7ac73c3a7bf38f2236f" },
        ];
        for (i, k) in kats.iter().enumerate() {
            let got = argon2id_derive_key(k.pwd.to_vec(), k.salt.to_vec(), k.m, k.t, k.p, k.len)
                .unwrap_or_else(|e| panic!("KAT #{i} 计算失败：{e}"));
            assert_eq!(
                hex::encode(&got),
                k.hex,
                "KAT #{i} 派生密钥与参考实现不一致"
            );
        }
    }

    #[test]
    fn argon2id_is_deterministic_and_salt_sensitive() {
        let a = argon2id_derive_key(b"pw".to_vec(), b"saltsalt".to_vec(), 256, 2, 1, 32).unwrap();
        let b = argon2id_derive_key(b"pw".to_vec(), b"saltsalt".to_vec(), 256, 2, 1, 32).unwrap();
        assert_eq!(a, b, "相同入参必须确定性一致");
        let c = argon2id_derive_key(b"pw".to_vec(), b"saltsblt".to_vec(), 256, 2, 1, 32).unwrap();
        assert_ne!(a, c, "不同 salt 必须产出不同密钥");
    }

    #[test]
    fn argon2id_rejects_bad_inputs() {
        // salt 过短
        assert!(argon2id_derive_key(b"pw".to_vec(), b"short".to_vec(), 256, 2, 1, 32).is_err());
        // output_len 过短
        assert!(argon2id_derive_key(b"pw".to_vec(), b"saltsalt".to_vec(), 256, 2, 1, 8).is_err());
        // output_len 过长
        assert!(
            argon2id_derive_key(b"pw".to_vec(), b"saltsalt".to_vec(), 256, 2, 1, 2048).is_err()
        );
        // m_cost 过小（Argon2 要求 m >= 8*p）
        assert!(argon2id_derive_key(b"pw".to_vec(), b"saltsalt".to_vec(), 1, 2, 1, 32).is_err());
    }

    // ---- HKDF-SHA256 RFC 5869 Appendix A 测试向量 ----
    fn h(s: &str) -> Vec<u8> {
        hex::decode(s).unwrap()
    }

    #[test]
    fn hkdf_rfc5869_case1() {
        let ikm = h("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
        let salt = h("000102030405060708090a0b0c");
        let info = h("f0f1f2f3f4f5f6f7f8f9");
        let okm = hkdf_sha256_derive_key(ikm, Some(salt), info, 42).unwrap();
        assert_eq!(
            hex::encode(okm),
            "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"
        );
    }

    #[test]
    fn hkdf_rfc5869_case2_long() {
        let ikm = h("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f");
        let salt = h("606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf");
        let info = h("b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");
        let okm = hkdf_sha256_derive_key(ikm, Some(salt), info, 82).unwrap();
        assert_eq!(
            hex::encode(okm),
            "b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87"
        );
    }

    #[test]
    fn hkdf_rfc5869_case3_no_salt() {
        // salt 与 info 均为空，覆盖 salt = None 路径。
        let ikm = h("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
        let okm = hkdf_sha256_derive_key(ikm, None, Vec::new(), 42).unwrap();
        assert_eq!(
            hex::encode(okm),
            "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8"
        );
    }

    #[test]
    fn hkdf_rejects_bad_output_len() {
        assert!(hkdf_sha256_derive_key(b"ikm-bytes".to_vec(), None, Vec::new(), 0).is_err());
        assert!(
            hkdf_sha256_derive_key(b"ikm-bytes".to_vec(), None, Vec::new(), 255 * 32 + 1).is_err()
        );
    }
}
