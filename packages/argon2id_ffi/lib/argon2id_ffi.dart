/// 自研 Argon2id + HKDF-SHA256 密钥派生（RustCrypto + 手写 dart:ffi，无 FRB）。
library;

export 'src/ffi/crypto_ffi.dart' show argon2idDeriveKey, hkdfSha256DeriveKey;
export 'src/ffi/errors.dart' show Argon2idFfiException;
