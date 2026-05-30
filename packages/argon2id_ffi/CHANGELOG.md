## 0.1.0

- Initial release.
- **Argon2id** (RFC 9106, version 0x13) and **HKDF-SHA256** (RFC 5869) via a thin
  `dart:ffi` binding over RustCrypto — no `flutter_rust_bridge`.
- Async API runs in an `Isolate`; native library is ~0.3 MB per architecture (2 symbols).
- Verified byte-for-byte against the C reference (`argon2-cffi` / P-H-C `libargon2`).
- Platforms: iOS, Android, macOS, Linux, Windows.
- iOS includes a Swift Package Manager manifest backed by a Rust static-library XCFramework,
  so Flutter can build with SPM enabled without falling back to the CocoaPods script phase.
