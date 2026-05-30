// 手写 dart:ffi 绑定 —— 符号解析按平台分流：
//
// - **iOS / macOS**：cargokit 把 Rust **静态链接**进 app 主二进制。运行期 `dlsym` 按名查找在
//   release/archive 下会因符号被 strip 而失败（已实测）。故用 **`@Native(symbol:)`**——编译期
//   静态引用，既让链接器保留符号、又不靠 dlsym 按名找，对 strip 免疫（macOS profile/AOT 已验证）。
// - **Android / Linux / Windows**：native 是**独立动态库**(`.so`/`.dll`)，其导出符号 release strip
//   后仍在（共享库的动态符号表是动态链接所需、不被剥）。故 `DynamicLibrary.open` + `lookupFunction`。
//   （Android 上 `@Native` 会回退进程查找，而 `.so` 是 RTLD_LOCAL 载入、符号不在进程全局——找不到。）
// - **host 测试**：`ARGON2ID_FFI_LIB` 指向 dylib，强制走 `lookupFunction` 路径。
//
// **绝不给这两个函数标 isLeaf**：Argon2 耗时 60ms-1s，isLeaf 会挂起 GC、冻结整个 VM。
library;

import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

// ---- C / Dart 函数签名 ----
typedef _Argon2idC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8>, ffi.Size,
  ffi.Pointer<ffi.Uint8>, ffi.Size,
  ffi.Uint32, ffi.Uint32, ffi.Uint32,
  ffi.Pointer<ffi.Uint8>, ffi.Size,
);
typedef Argon2idDart = int Function(
  ffi.Pointer<ffi.Uint8>, int,
  ffi.Pointer<ffi.Uint8>, int,
  int, int, int,
  ffi.Pointer<ffi.Uint8>, int,
);
typedef _HkdfC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8>, ffi.Size,
  ffi.Pointer<ffi.Uint8>, ffi.Size,
  ffi.Pointer<ffi.Uint8>, ffi.Size,
  ffi.Pointer<ffi.Uint8>, ffi.Size,
);
typedef HkdfDart = int Function(
  ffi.Pointer<ffi.Uint8>, int,
  ffi.Pointer<ffi.Uint8>, int,
  ffi.Pointer<ffi.Uint8>, int,
  ffi.Pointer<ffi.Uint8>, int,
);

// ---- iOS / macOS：`@Native`（编译期静态解析，抗 strip）----
@ffi.Native<_Argon2idC>(symbol: 'argon2id_ffi_derive')
external int _argon2idStatic(
  ffi.Pointer<ffi.Uint8> password, int passwordLen,
  ffi.Pointer<ffi.Uint8> salt, int saltLen,
  int mCost, int tCost, int parallelism,
  ffi.Pointer<ffi.Uint8> out, int outLen,
);

@ffi.Native<_HkdfC>(symbol: 'hkdf_sha256_ffi_derive')
external int _hkdfStatic(
  ffi.Pointer<ffi.Uint8> ikm, int ikmLen,
  ffi.Pointer<ffi.Uint8> salt, int saltLen,
  ffi.Pointer<ffi.Uint8> info, int infoLen,
  ffi.Pointer<ffi.Uint8> out, int outLen,
);

// ---- Android / Linux / Windows / host：独立动态库 + lookupFunction ----
ffi.DynamicLibrary? _dylib;
ffi.DynamicLibrary _openDylib() {
  final override = Platform.environment['ARGON2ID_FFI_LIB'];
  if (override != null && override.isNotEmpty) {
    return ffi.DynamicLibrary.open(override);
  }
  if (Platform.isWindows) return ffi.DynamicLibrary.open('argon2id_ffi.dll');
  return ffi.DynamicLibrary.open('libargon2id_ffi.so'); // Android / Linux
}

bool get _useStaticNative {
  final override = Platform.environment['ARGON2ID_FFI_LIB'];
  return (Platform.isIOS || Platform.isMacOS) &&
      (override == null || override.isEmpty);
}

/// 解析两个 native 函数（按平台选 @Native 或 lookupFunction）。可在任意 isolate 调用。
({Argon2idDart argon2id, HkdfDart hkdf}) resolveFns() {
  if (_useStaticNative) {
    return (argon2id: _argon2idStatic, hkdf: _hkdfStatic);
  }
  final lib = _dylib ??= _openDylib();
  return (
    argon2id: lib.lookupFunction<_Argon2idC, Argon2idDart>('argon2id_ffi_derive'),
    hkdf: lib.lookupFunction<_HkdfC, HkdfDart>('hkdf_sha256_ffi_derive'),
  );
}
