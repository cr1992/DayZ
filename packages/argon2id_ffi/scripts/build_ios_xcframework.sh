#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

crate_dir="rust"
package_dir="ios/argon2id_ffi"
include_dir="$package_dir/include"
staging_dir="$crate_dir/target/ios-spm"
device_lib="$staging_dir/aarch64-apple-ios/libargon2id_ffi.a"
sim_arm64_lib="$staging_dir/aarch64-apple-ios-sim/libargon2id_ffi.a"
sim_x86_64_lib="$staging_dir/x86_64-apple-ios/libargon2id_ffi.a"
sim_universal_lib="$staging_dir/ios-simulator/libargon2id_ffi.a"
xcframework="$package_dir/argon2id_ffi.xcframework"

cargo build --manifest-path "$crate_dir/Cargo.toml" --release --target aarch64-apple-ios
cargo build --manifest-path "$crate_dir/Cargo.toml" --release --target aarch64-apple-ios-sim
cargo build --manifest-path "$crate_dir/Cargo.toml" --release --target x86_64-apple-ios

mkdir -p "$(dirname "$device_lib")" "$(dirname "$sim_arm64_lib")" "$(dirname "$sim_x86_64_lib")" "$(dirname "$sim_universal_lib")"
cp "$crate_dir/target/aarch64-apple-ios/release/libargon2id_ffi.a" "$device_lib"
cp "$crate_dir/target/aarch64-apple-ios-sim/release/libargon2id_ffi.a" "$sim_arm64_lib"
cp "$crate_dir/target/x86_64-apple-ios/release/libargon2id_ffi.a" "$sim_x86_64_lib"

xcrun strip -S -x "$device_lib"
xcrun strip -S -x "$sim_arm64_lib"
xcrun strip -S -x "$sim_x86_64_lib"
xcrun lipo -create "$sim_arm64_lib" "$sim_x86_64_lib" -output "$sim_universal_lib"
xcrun strip -S -x "$sim_universal_lib"

rm -rf "$xcframework"
xcodebuild -create-xcframework \
  -library "$device_lib" -headers "$include_dir" \
  -library "$sim_universal_lib" -headers "$include_dir" \
  -output "$xcframework"
