# argon2id_ffi

Fast, native **Argon2id** key derivation (plus **HKDF-SHA256**) for Flutter — a thin
`dart:ffi` binding over the audited [RustCrypto](https://github.com/RustCrypto/password-hashes)
implementation. No `flutter_rust_bridge`, no heavy runtime: the whole native library is
**~0.3 MB per architecture** and exports just two C functions.

> ⚠️ **Status: pre-1.0, not independently audited.** The algorithms come from RustCrypto
> (audited), but this binding layer is not. Review before using in high-stakes production.
> Performance numbers below were measured on a dev machine, not a phone — run the included
> benchmark on your target.

## Why

The Dart/Flutter ecosystem's Argon2 options are either **pure Dart** (slow — seconds per
hash on mobile at sane parameters) or **`dargon2`** (native/fast but unmaintained for ~2
years, with an iOS plugin-declaration bug that strips symbols on release). `argon2id_ffi`
gives you native speed with a current, maintained toolchain and a minimal dependency surface.

## Features

- **Argon2id** (RFC 9106, version 0x13) — verified byte-for-byte against the C reference
  implementation (`argon2-cffi` / P-H-C `libargon2`).
- **HKDF-SHA256** (RFC 5869).
- Heavy work runs in an `Isolate` — the async API never blocks the UI thread.
- Inputs (`password`/`ikm`) are zeroized inside Rust after use (best-effort; see *Security*).
- iOS, Android, macOS, Linux, Windows.

## Install

```yaml
dependencies:
  argon2id_ffi: ^0.1.0
```

> **Build requirement:** native code is compiled from Rust via
> [cargokit](https://github.com/irondash/cargokit) at app build time, so a
> [Rust toolchain](https://rustup.rs) (`rustup` + the relevant targets) must be installed on
> the build machine / CI. (Precompiled-binary distribution is planned so consumers won't need
> Rust — see the repo issues.)

## Usage

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:argon2id_ffi/argon2id_ffi.dart';

// Argon2id — derive a 32-byte key.
final key = await argon2idDeriveKey(
  password: Uint8List.fromList(utf8.encode('correct horse battery staple')),
  salt: Uint8List.fromList(utf8.encode('a-random-16-byte-salt')), // >= 8 bytes
  mCost: 65536,   // memory cost in KiB (64 MiB)
  tCost: 3,       // iterations
  parallelism: 1,
  outputLen: 32,  // 16..1024
);

// HKDF-SHA256 — expand input key material.
final sub = await hkdfSha256DeriveKey(
  ikm: someKeyMaterial,
  salt: null,                 // null == RFC 5869 all-zero salt
  info: Uint8List.fromList(utf8.encode('myapp/subkey/v1')),
  outputLen: 32,
);
```

Invalid input (salt too short, `outputLen` out of range, etc.) throws
`Argon2idFfiException` with a numeric `code`.

## Performance

Measured on Apple Silicon (aarch64), 11 runs, median. **Absolute numbers are far faster than
a phone — they only matter relative to the C reference on the same machine.** The headline:
this is **dramatically faster than pure-Dart Argon2** and **on par with / slightly faster than
the C reference on ARM** (where the C SIMD path doesn't apply).

| Params (Argon2id) | argon2id_ffi (Rust) | C reference (argon2-cffi) |
|---|---|---|
| 64 MiB / t=3 / p=1 | **59.9 ms** | 77.2 ms |
| 32 MiB / t=4 / p=1 | 35.4 ms | 47.7 ms |

Single-architecture native library (stripped, link-time DCE): **iOS 0.317 MB · Android 0.333 MB**.
Reproduce with `dart run` of the bundled benchmark — see [`BENCHMARK.md`](BENCHMARK.md).

## Security notes

- Algorithms are RustCrypto's; this FFI wrapper is **not audited**.
- `password`/`ikm` are zeroized on the Rust side after use, but the **Dart-side `Uint8List`
  you pass in is GC-managed and cannot be reliably wiped** — clear sensitive buffers yourself
  where it matters. Derived keys are returned and not zeroized.
- **KDF determinism:** changing parameters (`mCost`/`tCost`/`parallelism`/`outputLen`/salt)
  changes the derived key. If you derive keys for storage, pin your parameters per version.

## License

MIT — see [LICENSE](LICENSE).
