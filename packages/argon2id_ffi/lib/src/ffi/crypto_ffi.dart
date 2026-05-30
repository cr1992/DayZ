// 公开异步 API：用 `Isolate.run` 把「C-ABI 调用 + marshalling」整体丢到一次性子 isolate，
// Argon2(64MiB, 60ms-1s) 不阻塞 UI isolate；返回的 Uint8List 可跨 isolate 回传。
//
// 符号经 `@Native`（bindings.dart）静态解析，可在子 isolate 直接调用；`ensureNativeLoaded()`
// 在子 isolate 内调用一次（host 上把 dylib 载入进程、device 上为静态符号无副作用）。
library;

import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'errors.dart';

/// 把 Dart 字节拷入新分配的 native 缓冲（空数组分配 1 字节占位、真实 len 传 0）。
ffi.Pointer<ffi.Uint8> _copyToNative(Uint8List data) {
  final p = malloc.allocate<ffi.Uint8>(data.isEmpty ? 1 : data.length);
  if (data.isNotEmpty) p.asTypedList(data.length).setAll(0, data);
  return p;
}

/// Argon2id 密钥派生。确定性：相同入参必得相同输出。
///
/// - [mCost] 内存代价，单位 KiB（64 MiB → 65536）。
/// - [outputLen] 派生密钥字节数，须 ∈ [16, 1024]。
/// 失败抛 [Argon2idFfiException]。
Future<Uint8List> argon2idDeriveKey({
  required Uint8List password,
  required Uint8List salt,
  required int mCost,
  required int tCost,
  required int parallelism,
  required int outputLen,
}) {
  return Isolate.run(() {
    final fns = resolveFns();
    final pwd = _copyToNative(password);
    final saltP = _copyToNative(salt);
    final out = malloc.allocate<ffi.Uint8>(outputLen);
    try {
      final code = fns.argon2id(
        pwd, password.length,
        saltP, salt.length,
        mCost, tCost, parallelism,
        out, outputLen,
      );
      throwIfError(code);
      return Uint8List.fromList(out.asTypedList(outputLen));
    } finally {
      malloc.free(pwd);
      malloc.free(saltP);
      malloc.free(out);
    }
  });
}

/// HKDF-SHA256 子密钥派生。[salt] 为 null 时走 RFC 5869 的全零 salt 路径。
/// 失败抛 [Argon2idFfiException]。
Future<Uint8List> hkdfSha256DeriveKey({
  required Uint8List ikm,
  Uint8List? salt,
  required Uint8List info,
  required int outputLen,
}) {
  return Isolate.run(() {
    final fns = resolveFns();
    final ikmP = _copyToNative(ikm);
    final ffi.Pointer<ffi.Uint8> saltP =
        salt == null ? ffi.nullptr : _copyToNative(salt);
    final infoP = _copyToNative(info);
    final out = malloc.allocate<ffi.Uint8>(outputLen);
    try {
      final code = fns.hkdf(
        ikmP, ikm.length,
        saltP, salt?.length ?? 0,
        infoP, info.length,
        out, outputLen,
      );
      throwIfError(code);
      return Uint8List.fromList(out.asTypedList(outputLen));
    } finally {
      malloc.free(ikmP);
      if (saltP != ffi.nullptr) malloc.free(saltP);
      malloc.free(infoP);
      malloc.free(out);
    }
  });
}
