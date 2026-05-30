//! C-ABI 包装层：把 `crypto.rs` 的纯逻辑函数暴露成稳定的 `extern "C"` 入口，
//! 供 Dart 手写 `dart:ffi` 调用。`crypto.rs` 本身只含纯算法、由 `cargo test` 覆盖。
//!
//! ## 内存契约（务必与 Dart 侧 `lib/src/ffi/` 一致）
//! - 所有 `*const u8` 入参（password/salt/ikm/info）：**调用方拥有、只读借入**；
//!   函数返回后调用方仍负责其生命周期与清零。Rust 不持有这些指针。
//! - `out` 缓冲：**调用方预分配 `out_len` 字节**并传 `(out_ptr, out_len)`；成功时 Rust
//!   写满恰好 `out_len` 字节。Rust **绝不分配返回堆指针**，故 Dart 无需也禁止对返回值 free。
//! - 派生结果落在 Dart 内存里、本层不擦；password/ikm 的 Rust 副本由 `crypto.rs` 内部 zeroize。
//!
//! ## panic 红线
//! 每个导出函数整体被 `std::panic::catch_unwind` 收口，panic 一律转 [`ERR_PANIC`]，
//! **绝不让 unwind 穿过 `extern "C"` 边界**（那是 UB）。因此发布 profile **必须保留
//! `panic = "unwind"`**，绝不能 `panic = "abort"`（会使 catch_unwind 直接 abort 进程）。

use core::slice;
use std::panic::{catch_unwind, AssertUnwindSafe};

use crate::api::crypto::{argon2id_derive_key, hkdf_sha256_derive_key};

// ---- 错误码（i32，与 Dart 侧 errors.dart 一一对应）----
/// 成功：`out` 已写满 `out_len` 字节。
pub const OK: i32 = 0;
/// 必需指针为 null（`out_ptr` 为空，或 salt/info 的 ptr 与 len 自相矛盾）。
pub const ERR_NULL_PTR: i32 = -1;
/// 长度参数非法（`out_len == 0`，或 salt/info 的 ptr/len 不一致）。
pub const ERR_BAD_LEN: i32 = -2;
/// 业务参数非法（output_len 越界 / salt 过短 / argon2 参数非法等，即 `crypto.rs` 返回 `Err`）。
pub const ERR_BAD_PARAM: i32 = -3;
/// 内部错误（计算成功但长度不符等防御性兜底）。
pub const ERR_INTERNAL: i32 = -4;
/// 捕获到 panic（已被 `catch_unwind` 拦截，未跨 FFI 边界）。
pub const ERR_PANIC: i32 = -100;

// ---- `#[used]` 锚点：这些导出函数没有 crate 内部引用，靠 `#[used]` + `#[no_mangle]`
// 防 LTO/链接器在 cargokit `-force_load` 之前把它们 dead-strip 掉。----
type Argon2idFn =
    unsafe extern "C" fn(*const u8, usize, *const u8, usize, u32, u32, u32, *mut u8, usize) -> i32;
type HkdfFn = unsafe extern "C" fn(
    *const u8,
    usize,
    *const u8,
    usize,
    *const u8,
    usize,
    *mut u8,
    usize,
) -> i32;
#[used]
static _KEEP_ARGON2: Argon2idFn = argon2id_ffi_derive;
#[used]
static _KEEP_HKDF: HkdfFn = hkdf_sha256_ffi_derive;

/// 把只读 `(ptr, len)` 转成 `&[u8]`，校验空指针/零长一致性。
/// 约定：`len == 0` 时允许 `ptr` 为 null（返回空切片，不 deref）。
///
/// # Safety
/// `ptr` 在 `len > 0` 时须指向至少 `len` 字节可读内存。
unsafe fn checked_slice<'a>(ptr: *const u8, len: usize) -> Result<&'a [u8], i32> {
    if len == 0 {
        return Ok(&[]);
    }
    if ptr.is_null() {
        return Err(ERR_NULL_PTR);
    }
    Ok(slice::from_raw_parts(ptr, len))
}

/// Argon2id：调用方分配 `out`（长度须 == `out_len`）。返回错误码。
///
/// # Safety
/// 见模块级内存契约：各 `*const u8` 指向对应 len 字节可读内存（len==0 时可为 null）；
/// `out_ptr` 指向恰好 `out_len` 字节可写内存；调用期间各缓冲不被其它线程改写。
#[no_mangle]
pub unsafe extern "C" fn argon2id_ffi_derive(
    password_ptr: *const u8,
    password_len: usize,
    salt_ptr: *const u8,
    salt_len: usize,
    m_cost: u32,
    t_cost: u32,
    parallelism: u32,
    out_ptr: *mut u8,
    out_len: usize,
) -> i32 {
    catch_unwind(AssertUnwindSafe(|| {
        if out_len == 0 {
            return ERR_BAD_LEN;
        }
        if out_ptr.is_null() {
            return ERR_NULL_PTR;
        }
        let password = match checked_slice(password_ptr, password_len) {
            Ok(s) => s,
            Err(code) => return code,
        };
        let salt = match checked_slice(salt_ptr, salt_len) {
            Ok(s) => s,
            Err(code) => return code,
        };

        // crypto.rs 收 Vec 并自行 zeroize 那份 password 副本。
        match argon2id_derive_key(
            password.to_vec(),
            salt.to_vec(),
            m_cost,
            t_cost,
            parallelism,
            out_len as u32,
        ) {
            Ok(derived) => {
                if derived.len() != out_len {
                    return ERR_INTERNAL;
                }
                let out = slice::from_raw_parts_mut(out_ptr, out_len);
                out.copy_from_slice(&derived);
                OK
            }
            Err(_) => ERR_BAD_PARAM,
        }
    }))
    .unwrap_or(ERR_PANIC)
}

/// HKDF-SHA256：`salt_ptr == null && salt_len == 0` 表示 None；
/// `salt_ptr != null && salt_len > 0` 表示 `Some(salt)`；其余组合视为参数非法。
///
/// # Safety
/// 见模块级内存契约。
#[no_mangle]
pub unsafe extern "C" fn hkdf_sha256_ffi_derive(
    ikm_ptr: *const u8,
    ikm_len: usize,
    salt_ptr: *const u8,
    salt_len: usize,
    info_ptr: *const u8,
    info_len: usize,
    out_ptr: *mut u8,
    out_len: usize,
) -> i32 {
    catch_unwind(AssertUnwindSafe(|| {
        if out_len == 0 {
            return ERR_BAD_LEN;
        }
        if out_ptr.is_null() {
            return ERR_NULL_PTR;
        }
        let ikm = match checked_slice(ikm_ptr, ikm_len) {
            Ok(s) => s,
            Err(code) => return code,
        };
        let info = match checked_slice(info_ptr, info_len) {
            Ok(s) => s,
            Err(code) => return code,
        };

        // salt 三态：None / Some / 非法。
        let salt_opt: Option<Vec<u8>> = if salt_ptr.is_null() {
            if salt_len != 0 {
                return ERR_BAD_LEN;
            }
            None
        } else {
            if salt_len == 0 {
                return ERR_BAD_LEN;
            }
            Some(slice::from_raw_parts(salt_ptr, salt_len).to_vec())
        };

        match hkdf_sha256_derive_key(ikm.to_vec(), salt_opt, info.to_vec(), out_len as u32) {
            Ok(derived) => {
                if derived.len() != out_len {
                    return ERR_INTERNAL;
                }
                let out = slice::from_raw_parts_mut(out_ptr, out_len);
                out.copy_from_slice(&derived);
                OK
            }
            Err(_) => ERR_BAD_PARAM,
        }
    }))
    .unwrap_or(ERR_PANIC)
}
