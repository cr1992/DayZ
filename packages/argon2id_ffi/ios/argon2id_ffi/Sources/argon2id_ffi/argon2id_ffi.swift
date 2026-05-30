import Foundation
import argon2id_ffi_native

@_cdecl("argon2id_ffi_spm_anchor")
public func argon2id_ffi_spm_anchor() -> Int32 {
    let argon2 = argon2id_ffi_derive(
        nil,
        0,
        nil,
        0,
        0,
        0,
        0,
        nil,
        0
    )
    let hkdf = hkdf_sha256_ffi_derive(
        nil,
        0,
        nil,
        0,
        nil,
        0,
        nil,
        0
    )
    return argon2 + hkdf
}
