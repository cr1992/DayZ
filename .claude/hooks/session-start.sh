#!/bin/bash
# 云端会话（Claude Code on the web）启动钩子：装 Flutter SDK + 拉依赖，
# 让 `flutter test` / `dart analyze` 开箱可跑。本地会话直接跳过。
#
# Flutter 版本钉在 3.44.4（Dart 3.12.2）：与 pubspec.lock（flutter >=3.44.0）
# 和现有 golden 基线生成期一致；升级 Flutter 时同步改这里。
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_VERSION="3.44.4"
SDK_ROOT="${HOME}/sdk"
FLUTTER_HOME="${SDK_ROOT}/flutter"

current_version() {
  local stamp="${FLUTTER_HOME}/bin/cache/flutter.version.json"
  [ -f "${stamp}" ] && sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p' "${stamp}" || true
}

if [ "$(current_version)" != "${FLUTTER_VERSION}" ]; then
  rm -rf "${FLUTTER_HOME}"
  mkdir -p "${SDK_ROOT}"
  curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C "${SDK_ROOT}"
fi

git config --global --get-all safe.directory | grep -qx "${FLUTTER_HOME}" \
  || git config --global --add safe.directory "${FLUTTER_HOME}"

export PATH="${FLUTTER_HOME}/bin:${PATH}"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${FLUTTER_HOME}/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE}"
fi

flutter --disable-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
flutter pub get

# argon2id_ffi 在 Linux host 走动态库（无预编译产物）：有 cargo 就现编一份，并经
# ARGON2ID_FFI_LIB 指给测试，否则 test/security 下的 KDF 用例会因找不到 .so 失败。
# 尽力而为：编不出来只影响这几条 KDF 用例，不拦会话启动。
ARGON2_TARGET="${HOME}/.cache/dayz-argon2id-ffi"
if command -v cargo >/dev/null 2>&1 \
  && CARGO_TARGET_DIR="${ARGON2_TARGET}" \
    cargo build --release --locked --manifest-path packages/argon2id_ffi/rust/Cargo.toml; then
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "export ARGON2ID_FFI_LIB=\"${ARGON2_TARGET}/release/libargon2id_ffi.so\"" >> "${CLAUDE_ENV_FILE}"
  fi
else
  echo "warn: argon2id_ffi not built; test/security KDF cases will fail on Linux" >&2
fi
