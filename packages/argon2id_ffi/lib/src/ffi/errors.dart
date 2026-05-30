// 错误码 → Dart 异常映射。常量必须与 Rust 侧 `rust/src/api/ffi.rs` 完全一致。
// 约定：0 = 成功；负数 = 分类失败。不跨 FFI 传字符串（避免内存归属纠纷）。
library;

/// C-ABI 调用失败时抛出。
class Argon2idFfiException implements Exception {
  final int code;
  final String message;
  Argon2idFfiException(this.code, this.message);
  @override
  String toString() => 'Argon2idFfiException($code): $message';
}

const int kErrOk = 0;
const int kErrNullPtr = -1; // 必需指针为空
const int kErrBadLen = -2; // out_len/salt_len 长度非法
const int kErrBadParam = -3; // KDF 参数非法（salt 过短 / output_len 越界 / m<8p 等）
const int kErrInternal = -4; // 内部错误（长度防御性兜底）
const int kErrPanic = -100; // Rust 侧 catch_unwind 捕获到 panic

String _describe(int code) {
  switch (code) {
    case kErrNullPtr:
      return '入参指针为空';
    case kErrBadLen:
      return 'out_len 或 salt 长度非法';
    case kErrBadParam:
      return 'KDF 参数非法（salt 过短 / output_len 越界 / m_cost 过小等）';
    case kErrInternal:
      return '内部错误';
    case kErrPanic:
      return 'Rust 侧发生 panic（已被 catch_unwind 拦截）';
    default:
      return '未知错误码 $code';
  }
}

/// 非 0 即抛。
void throwIfError(int code) {
  if (code != kErrOk) throw Argon2idFfiException(code, _describe(code));
}
