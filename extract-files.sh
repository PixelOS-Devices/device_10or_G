#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=G
VENDOR=10or

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/lib/libubifocus.so|vendor/lib/libHAFIAFalSDE1.so|vendor/lib/libtrueportrait.so|vendor/lib/libmmcamera_hdr_gb_lib.so|vendor/lib/libAltek_AF.so|vendor/lib/libts_detected_face_hal.so|vendor/lib/libseemore.so|vendor/lib/libIQM_OTP_Correction.so|vendor/lib/libfcell.so|vendor/lib/libts_face_beautify_hal.so|vendor/lib/libalCMotion.so|vendor/lib/libchromaflash.so|vendor/lib/liboptizoom.so|vendor/lib/libIAFalSDE1.so|vendor/lib/libIQ_Match_Lib.so)
            "${PATCHELF}" --replace-needed "libstdc++.so" "libstdc++_vendor.so" "${2}"
            ;;
        vendor/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so)
            "${PATCHELF_0_8}" --remove-needed "libprotobuf-cpp-lite.so" "${2}"
            ;;
        vendor/lib64/libgf_algo.so|vendor/lib64/libgf_ca.so|vendor/lib64/libgf_hal.so)
            "${PATCHELF_0_8}" --remove-needed "libstdc++.so" "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
