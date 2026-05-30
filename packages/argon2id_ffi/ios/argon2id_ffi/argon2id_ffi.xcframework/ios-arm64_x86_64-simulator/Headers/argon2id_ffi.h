#ifndef ARGON2ID_FFI_H
#define ARGON2ID_FFI_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int32_t argon2id_ffi_derive(
    const uint8_t *password_ptr,
    size_t password_len,
    const uint8_t *salt_ptr,
    size_t salt_len,
    uint32_t m_cost,
    uint32_t t_cost,
    uint32_t parallelism,
    uint8_t *out_ptr,
    size_t out_len
);

int32_t hkdf_sha256_ffi_derive(
    const uint8_t *ikm_ptr,
    size_t ikm_len,
    const uint8_t *salt_ptr,
    size_t salt_len,
    const uint8_t *info_ptr,
    size_t info_len,
    uint8_t *out_ptr,
    size_t out_len
);

#ifdef __cplusplus
}
#endif

#endif
