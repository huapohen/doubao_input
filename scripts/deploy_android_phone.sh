#!/usr/bin/env bash
# Deploy both Android clones to the physical phone (not emulators).
# Usage: ./scripts/deploy_android_phone.sh [serial] [--set-default]
set -euo pipefail
ADB="${ADB:-/Users/lwblx/Library/Android/sdk/platform-tools/adb}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERIAL="${1:-}"
if [[ "${SERIAL:-}" == --* ]]; then SERIAL=""; fi
if [[ -z "$SERIAL" ]]; then
  SERIAL="$($ADB devices | awk '$2=="device" && $1 !~ /^emulator-/{print $1; exit}')"
fi
if [[ -z "$SERIAL" ]]; then
  cat <<'TXT'
未检测到物理 Android 设备（只有模拟器）。
请在手机上开启：
  1. 设置 → 关于手机 → 连续点击 HyperOS/版本号 7 次
  2. 设置 → 更多设置 → 开发者选项 → USB 调试（打开）
  3. 同时打开“USB 安装”“USB 调试（安全设置）”
  4. USB 连接方式选“文件传输/MTP”，并在手机上允许 RSA 调试
然后重新运行本脚本。
TXT
  exit 1
fi
echo "Device: $SERIAL"
$ADB -s "$SERIAL" install -r -g "$ROOT/dist/doubao-input-android-native.apk"
$ADB -s "$SERIAL" install -r -g "$ROOT/dist/doubao-input-flutter-debug.apk"
$ADB -s "$SERIAL" shell ime enable com.huapohen.doubaoinput.android/.ime.DoubaoImeService || true
if [[ "${2:-}" == "--set-default" ]]; then
  $ADB -s "$SERIAL" shell ime set com.huapohen.doubaoinput.android/.ime.DoubaoImeService || true
fi
$ADB -s "$SERIAL" shell am start -n com.huapohen.doubaoinput.android/.settings.MainActivity || true
echo "已安装：豆包输入法（原生复刻）与 Flutter 通用版"
echo "原生 IME 已 enable；如需设为默认：$ADB -s $SERIAL shell ime set com.huapohen.doubaoinput.android/.ime.DoubaoImeService"
