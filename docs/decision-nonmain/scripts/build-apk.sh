#!/usr/bin/env bash
# 在电脑上打出支持 StartLux 决策模型的 Mika APK
# 用法：把本目录放到任意位置，装好 JDK 17 后执行 bash build-apk.sh [本机 Android SDK 路径]
# 例：bash build-apk.sh ~/Android/Sdk
set -euo pipefail

SDK_DIR="${1:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)/Mika"

if [ ! -d "$REPO" ]; then
  echo "没有找到源码目录，先克隆："
  git clone https://github.com/wangzan101/Mika.git "$REPO"
fi

cd "$REPO"
echo "sdk.dir=$SDK_DIR" > local.properties

# 应用补丁（只含 ModelSetupViewModel / ModelSetupScreen / ModelsScreen / strings_setup 三个语言）
PATCH="$(cd "$(dirname "$0")/../patches" && pwd)/mika-startlux-support-decision-nonmain.patch"
git apply --check "$PATCH" && git apply "$PATCH" || echo "补丁已经打过，跳过"

./gradlew assembleDebug
APK="$REPO/app/build/outputs/apk/debug/app-debug.apk"
cp "$APK" "$(cd "$(dirname "$0")/.." && pwd)/mika-test-decision-nonmain.apk"
echo "APK 已生成：$(cd "$(dirname "$0")/.." && pwd)/mika-test-decision-nonmain.apk"
adb install -r "$(cd "$(dirname "$0")/.." && pwd)/mika-test-decision-nonmain.apk" 2>/dev/null || echo "（没有连设备，跳过安装）"
