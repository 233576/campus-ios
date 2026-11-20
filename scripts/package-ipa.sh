#!/usr/bin/env bash
# 把 Release-iphoneos/Campus.app 打成未签名 .ipa（Payload/ 结构）
# 用法：bash scripts/package-ipa.sh [APP_PATH]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-${ROOT_DIR}/build/Build/Products/Release-iphoneos/Campus.app}"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/dist}"
IPA_NAME="${IPA_NAME:-Campus-unsigned.ipa}"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "找不到 .app：${APP_PATH}" >&2
  echo "先执行 xcodebuild ... -configuration Release -sdk iphoneos build" >&2
  exit 1
fi

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/Payload"
cp -R "${APP_PATH}" "${OUT_DIR}/Payload/Campus.app"

# 未签名包去掉残留的签名目录，避免重签工具报错
rm -rf "${OUT_DIR}/Payload/Campus.app/_CodeSignature"

(
  cd "${OUT_DIR}"
  zip -qry "${IPA_NAME}" Payload
  zip -qry "Campus-unsigned-app.zip" Payload/Campus.app
)

echo "已生成：${OUT_DIR}/${IPA_NAME}"
ls -lh "${OUT_DIR}"
