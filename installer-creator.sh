#!/usr/bin/env sh

# SYNOPSIS
# Runs tasks to generate Monolith's Gruntz (1999) installer for UNIX-like opertaing system.

# DESCRIPTION
# This scripts tries to convert Gruntz ISO file to an installer that is compatible with UNIX-like opertaing system.

# REQUIREMENTS
# - wget
# - awk
# - p7zip
# - Qt Installer Framework 3.0 or higher
# - UPX (Optional)

# PARAMETER Iso (${1})
# - Path to Gruntz ISO file
# - Default, gruntz.iso

RELATIVE_PATH=$(dirname "${0}")

INSTALLER_NAME="${RELATIVE_PATH}/dist/gruntz-installer"
INSTALLER_EXTENSION='.run'

# Gruntz seems to be failing to play movie (MOVIEZ/*.FEC) files on Linux platform with wine software,
# until this issue hasn't been solved we'll be excluding them.
EXCLUDE_MOVIES= # Defaults to 1.

CRACK_BINARIES_IF_POSSIBLE= # Defaults to 1.
USE_ORIGINAL_CRACK= # Defaults to 0.
COMPRESS_INSTALLER_IF_POSSIBLE= # Defaults to 1.

WGET_FALLBACK=
P7ZIP_FALLBACK=
BINARYCREATOR_FALLBACK=
UPX_FALLBACK=

# Handle parameters.
if [ -n "${1}" ]; then
    MEDIA="${1}"
fi

# If settings.ini file is not found, then lets generate it by copying sample.
if [ ! -f "${RELATIVE_PATH}/settings.ini" ]; then
    cp "${RELATIVE_PATH}/settings.ini.sample" "${RELATIVE_PATH}/settings.ini"
fi

# Function that reads settings.ini file and return values from it.
GET_VALUE_FROM_INI_FILE () {
    echo $(awk -F '=' '/'${1}'/ {print $2}' "${RELATIVE_PATH}/settings.ini")
}

# Reading settings from settings.ini file.
if [ -z "${MEDIA}" ]; then
    INI_MEDIA=$(GET_VALUE_FROM_INI_FILE media)

    if [ -n "${INI_MEDIA}" ]; then
        MEDIA=${INI_MEDIA}
    else
        MEDIA="${RELATIVE_PATH}/gruntz.iso"
    fi
fi

if [ -z ${EXCLUDE_MOVIES} ]; then
    INI_EXCLUDE_MOVIES=$(GET_VALUE_FROM_INI_FILE unix_exclude_movies)

    if [ -n "${INI_EXCLUDE_MOVIES}" ]; then
        EXCLUDE_MOVIES=${INI_EXCLUDE_MOVIES}
    else
        EXCLUDE_MOVIES=1
    fi
fi

if [ -z ${CRACK_BINARIES_IF_POSSIBLE} ]; then
    INI_CRACK_BINARIES_IF_POSSIBLE=$(GET_VALUE_FROM_INI_FILE crack_binaries_if_possible)

    if [ -n "${INI_CRACK_BINARIES_IF_POSSIBLE}" ]; then
        CRACK_BINARIES_IF_POSSIBLE=${INI_CRACK_BINARIES_IF_POSSIBLE}
    else
        CRACK_BINARIES_IF_POSSIBLE=1
    fi
fi

if [ -z ${USE_ORIGINAL_CRACK} ]; then
    INI_USE_ORIGINAL_CRACK=$(GET_VALUE_FROM_INI_FILE use_original_crack)

    if [ -n "${INI_USE_ORIGINAL_CRACK}" ]; then
        USE_ORIGINAL_CRACK=${INI_USE_ORIGINAL_CRACK}
    else
        USE_ORIGINAL_CRACK=0
    fi
fi

if [ -z ${COMPRESS_INSTALLER_IF_POSSIBLE} ]; then
    INI_COMPRESS_INSTALLER_IF_POSSIBLE=$(GET_VALUE_FROM_INI_FILE compress_installer_if_possible)

    if [ -n "${INI_COMPRESS_INSTALLER_IF_POSSIBLE}" ]; then
        COMPRESS_INSTALLER_IF_POSSIBLE=${INI_COMPRESS_INSTALLER_IF_POSSIBLE}
    else
        COMPRESS_INSTALLER_IF_POSSIBLE=1
    fi
fi

# Reading fallbacks from settings.ini file.
if [ -z ${WGET_FALLBACK} ]; then
    INI_WGET_FALLBACK=$(GET_VALUE_FROM_INI_FILE unix_wget_fallback)

    if [ -n "${INI_WGET_FALLBACK}" ]; then
        WGET_FALLBACK=${INI_WGET_FALLBACK}
    fi
fi

if [ -z ${P7ZIP_FALLBACK} ]; then
    INI_P7ZIP_FALLBACK=$(GET_VALUE_FROM_INI_FILE unix_p7zip_fallback)

    if [ -n "${INI_P7ZIP_FALLBACK}" ]; then
        P7ZIP_FALLBACK=${INI_P7ZIP_FALLBACK}
    fi
fi

if [ -z ${BINARYCREATOR_FALLBACK} ]; then
    INI_BINARYCREATOR_FALLBACK=$(GET_VALUE_FROM_INI_FILE unix_binarycreator_fallback)

    if [ -n "${INI_BINARYCREATOR_FALLBACK}" ]; then
        BINARYCREATOR_FALLBACK=${INI_BINARYCREATOR_FALLBACK}
    fi
fi

if [ -z ${UPX_FALLBACK} ]; then
    INI_UPX_FALLBACK=$(GET_VALUE_FROM_INI_FILE unix_upx_fallback)

    if [ -n "${INI_UPX_FALLBACK}" ]; then
        UPX_FALLBACK=${INI_UPX_FALLBACK}
    fi
fi

GRUNTZ_DATA_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz/data"
GRUNTZ_DATA_MOVIES_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz.movies/data"

PATCH_DATA_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz.patch/data"

EDITOR_DATA_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz.editor.editor/data"
SAMPLES_DATA_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz.editor.samples/data/CUSTOM"

CUSTOM_LEVEL_FORKLAND_DATA_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz.custom.battles.forkland/data/CUSTOM"
CUSTOM_LEVEL_DIRTLAND_DATA_OUTPUT_DIR="${RELATIVE_PATH}/packages/eu.murda.gruntz.custom.battles.dirtland/data/CUSTOM"

PATCH_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-patch.zip'
PATCH_ARCHIVE_NAME="${RELATIVE_PATH}/tmp/$(basename ${PATCH_DOWNLOAD_URL})"

EDITOR_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-editor.zip'
EDITOR_ARCHIVE_NAME="${RELATIVE_PATH}/tmp/$(basename ${EDITOR_DOWNLOAD_URL})"

SAMPLES_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-sample-levels.zip'
SAMPLES_ARCHIVE_NAME="${RELATIVE_PATH}/tmp/$(basename ${SAMPLES_DOWNLOAD_URL})"

CUSTOM_LEVEL_FORKLAND_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-forkland.zip'
CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME="${RELATIVE_PATH}/tmp/$(basename ${CUSTOM_LEVEL_FORKLAND_DOWNLOAD_URL})"

CUSTOM_LEVEL_DIRTLAND_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-dirtland.zip'
CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME="${RELATIVE_PATH}/tmp/$(basename ${CUSTOM_LEVEL_DIRTLAND_DOWNLOAD_URL})"

TEST_MEDIA () {
    if [ ! -f "${MEDIA}" ]; then
        echo "> Specified ISO file doesn't exist on your filesystem."
        echo '> Aborting.'
        exit 1
    fi

    VALID_HASH_FOUND=0

    for VALID_HASH in \
        '275547756A472DA85298F7B86FBAF197'
    do
        MEDIA_HASH=$(md5sum "${MEDIA}" | cut -d ' ' -f 1)

        if [ "${VALID_HASH}" = "${MEDIA_HASH^^}" ]; then
            VALID_HASH_FOUND=1
            break
        fi
    done

    if [ "${VALID_HASH_FOUND}" != '1' ]; then
        echo "> Specified ISO file doesn't match with required fingerprint."
        echo '> Aborting.'
        exit 1
    fi
}

CLEAR_DATA_OUTPUT_DIRS () {
    for DIR_TO_CLEAR in $(find "${RELATIVE_PATH}" -type d -name 'data')
    do
        rm -r "${DIR_TO_CLEAR:?}/"*
    done
}

EXPAND_MEDIA () {
    "${P7ZIP}" x -aoa "-o${GRUNTZ_DATA_OUTPUT_DIR}" "${MEDIA}"
}

MERGE_SUBDIRECTORY_TO_ROOT () {
    SUBDIRECTORY="${GRUNTZ_DATA_OUTPUT_DIR}/${1}"

    if [ -d "${SUBDIRECTORY}" ]; then
        mv "${SUBDIRECTORY}/"* "${GRUNTZ_DATA_OUTPUT_DIR}"
        rm -r "${SUBDIRECTORY}"
    fi
}

REMOVE_USELESS_FILES () {
    for USELESS_FILE in \
        'AUTORUN.EXE' \
        'AUTORUN.INF' \
        'CDTEST.EXE' \
        'PREVIEWS' \
        'PREVIEW.EXE' \
        '_SETUP.DLL' \
        '_SETUP.LIB' \
        'SETUP.EXE' \
        'SETUP.INS' \
        'SETUP.PKG' \
        'UNINST.EXE' \
        '_INST32I.EX_' \
        '_ISDEL.EXE' \
        '_ISRES.DLL' \
        'GRUNTZ.HLP' \
        'GRUNTZ.URL' \
        'REGISTER.URL' \
        'REDIST' \
        'SYSTEM'
    do
        USELESS_FILE_PATH="${GRUNTZ_DATA_OUTPUT_DIR}/${USELESS_FILE}"

        if [ -f "${USELESS_FILE_PATH}" ]; then
            rm "${USELESS_FILE_PATH}"
        fi

        if [ -d "${USELESS_FILE_PATH}" ]; then
            rm -r "${USELESS_FILE_PATH}"
        fi
    done
}

RENAME_FILES () {
    if [ -f "${GRUNTZ_DATA_OUTPUT_DIR}/AUTORUN.ICO" ]; then
        mv "${GRUNTZ_DATA_OUTPUT_DIR}/AUTORUN.ICO" "${GRUNTZ_DATA_OUTPUT_DIR}/GRUNTZ.ICO"
    fi
}

MOVE_MOVIES_TO_SEPARATE_PACKAGE () {
    if [ -d "${GRUNTZ_DATA_OUTPUT_DIR}/MOVIEZ" ]; then
        mv "${GRUNTZ_DATA_OUTPUT_DIR}/MOVIEZ" "${GRUNTZ_DATA_MOVIES_OUTPUT_DIR}"
    fi
}

IMPORT_PATCH () {
    if [ ! -f "${PATCH_ARCHIVE_NAME}" ]; then
        "${WGET}" "${PATCH_DOWNLOAD_URL}" -O "${PATCH_ARCHIVE_NAME}"
    fi

    if [ -f "${PATCH_ARCHIVE_NAME}" ]; then
        "${P7ZIP}" x -aoa "-o${PATCH_DATA_OUTPUT_DIR}" "${PATCH_ARCHIVE_NAME}"
    fi
}

IMPORT_EDITOR () {
    if [ ! -f "${EDITOR_ARCHIVE_NAME}" ]; then
        "${WGET}" "${EDITOR_DOWNLOAD_URL}" -O "${EDITOR_ARCHIVE_NAME}"
    fi

    if [ -f "${EDITOR_ARCHIVE_NAME}" ]; then
        "${P7ZIP}" x -aoa "-o${EDITOR_DATA_OUTPUT_DIR}" "${EDITOR_ARCHIVE_NAME}"
    fi
}

IMPORT_SAMPLES () {
    if [ ! -f "${SAMPLES_ARCHIVE_NAME}" ]; then
        "${WGET}" "${SAMPLES_DOWNLOAD_URL}" -O "${SAMPLES_ARCHIVE_NAME}"
    fi

    if [ -f "${SAMPLES_ARCHIVE_NAME}" ]; then
        "${P7ZIP}" x -aoa "-o${SAMPLES_DATA_OUTPUT_DIR}" "${SAMPLES_ARCHIVE_NAME}"
    fi
}

IMPORT_CUSTOM_LEVEL_FORKLAND () {
    if [ ! -f "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}" ]; then
        "${WGET}" "${CUSTOM_LEVEL_FORKLAND_DOWNLOAD_URL}" -O "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}"
    fi

    if [ -f "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}" ]; then
        "${P7ZIP}" x -aoa "-o${CUSTOM_LEVEL_FORKLAND_DATA_OUTPUT_DIR}" "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}"
    fi
}

IMPORT_CUSTOM_LEVEL_DIRTLAND () {
    if [ ! -f "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}" ]; then
        "${WGET}" "${CUSTOM_LEVEL_DIRTLAND_DOWNLOAD_URL}" -O "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}"
    fi

    if [ -f "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}" ]; then
        "${P7ZIP}" x -aoa "-o${CUSTOM_LEVEL_DIRTLAND_DATA_OUTPUT_DIR}" "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}"
    fi
}

REPLACE_BYTE () {
    printf "$(printf '\\x%02X' ${3})" | dd of="${1}" bs=1 seek=$(printf "%d" ${2}) count=1 conv=notrunc &> /dev/null
}

CONVERT_BINARIES () {
    if [ "${CRACK_BINARIES_IF_POSSIBLE}" = '1' ]; then
        EXE_FILE="${GRUNTZ_DATA_OUTPUT_DIR}/GRUNTZ.EXE"
        EXE_HASH=$(md5sum "${EXE_FILE}" | cut -d ' ' -f 1)

        case "${EXE_HASH^^}" in
            '81C7F648DB99501BED6E1EE71E66E4A0')
                echo "> Cracking ${EXE_FILE}"

                if [ "${USE_ORIGINAL_CRACK}" = '1' ]; then
                    REPLACE_BYTE "${EXE_FILE}" 0x0001F4CC 0x2E
                    REPLACE_BYTE "${EXE_FILE}" 0x0001F4A1 0xEB
                    REPLACE_BYTE "${EXE_FILE}" 0x0001F4F3 0x90
                    REPLACE_BYTE "${EXE_FILE}" 0x0001F4F4 0x90
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AE86 0x5C
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AE9E 0x5C
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA1 0x52
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA2 0x55
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA3 0x4E
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA4 0x54
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA5 0x5A
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA6 0x2E
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA7 0x45
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA8 0x58
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEA9 0x45
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEAA 0x00
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEAB 0x00
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEAC 0x00
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEAD 0x00
                    REPLACE_BYTE "${EXE_FILE}" 0x0020AEAE 0x00
                    REPLACE_BYTE "${EXE_FILE}" 0x0020F4BA 0x5C
                    REPLACE_BYTE "${EXE_FILE}" 0x0020F826 0x5C
                    REPLACE_BYTE "${EXE_FILE}" 0x0020F856 0x5C
                    REPLACE_BYTE "${EXE_FILE}" 0x00212692 0x5C
                    REPLACE_BYTE "${EXE_FILE}" 0x002126AE 0x5C
                else
                    REPLACE_BYTE "${EXE_FILE}" 0x0001F15A 0x93
                fi
                ;;
        esac

        PATCH_FILE="${PATCH_DATA_OUTPUT_DIR}/GRUNTZ.EXE"
        PATCH_HASH=$(md5sum "${PATCH_FILE}" | cut -d ' ' -f 1)

        case "${PATCH_HASH^^}" in
            '199D4613E4587E1D720623DC11569E4D')
                echo "> Cracking ${PATCH_FILE}"

                if [ "${USE_ORIGINAL_CRACK}" = '1' ]; then
                    REPLACE_BYTE "${PATCH_FILE}" 0x0001F4DC 0x2E
                    REPLACE_BYTE "${PATCH_FILE}" 0x0001F4B1 0xEB
                    REPLACE_BYTE "${PATCH_FILE}" 0x0001F503 0x90
                    REPLACE_BYTE "${PATCH_FILE}" 0x0001F504 0x90
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B286 0x5C
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B29E 0x5C
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A1 0x52
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A2 0x55
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A3 0x4E
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A4 0x54
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A5 0x5A
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A6 0x2E
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A7 0x45
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A8 0x58
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2A9 0x45
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2AA 0x00
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2AB 0x00
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2AC 0x00
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2AD 0x00
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020B2AE 0x00
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020F862 0x5C
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020FBCE 0x5C
                    REPLACE_BYTE "${PATCH_FILE}" 0x0020FBFE 0x5C
                    REPLACE_BYTE "${PATCH_FILE}" 0x002129F2 0x5C
                    REPLACE_BYTE "${PATCH_FILE}" 0x00212A0E 0x5C
                else
                    REPLACE_BYTE "${PATCH_FILE}" 0x0001F16A 0x93
                fi
                ;;
        esac
    fi
}

BUILD_INSTALLER () {
    echo "> Creating installer."

    COMMAND="${BINARYCREATOR} --offline-only"
    COMMAND="${COMMAND} -c ${RELATIVE_PATH}/config/config.xml -p ${RELATIVE_PATH}/packages"
    COMMAND="${COMMAND} -e eu.murda.gruntz.ddraw,eu.murda.gruntz.dgvoodoo.ddraw"

    if [ "${EXCLUDE_MOVIES}" != 0 ]; then
        COMMAND="${COMMAND},eu.murda.gruntz.movies"
        INSTALLER_NAME="${INSTALLER_NAME}-no-movie"
    fi

    INSTALLER_NAME="${INSTALLER_NAME}${INSTALLER_EXTENSION}"
    COMMAND="${COMMAND} ${INSTALLER_NAME}"
    eval "${COMMAND}"
}

COMPRESS_INSTALLER () {
    if [ "${COMPRESS_INSTALLER_IF_POSSIBLE}" = '1' ]; then
        if [ -f "${INSTALLER_NAME}" ]; then
            echo "> Compressing Installer to save disk space."
            "${UPX}" -9 "${INSTALLER_NAME}"
        fi
    fi
}

if ! command -v wget 1> /dev/null 2>&1; then
    if [ -n "${WGET_FALLBACK}" ]; then
        WGET="${WGET_FALLBACK}"
    else
        echo "> Unable to find wget from your environment's PATH variable."
        echo '> Aborting.'
        exit 1
    fi
else
    WGET="$(command -v wget 2> /dev/null)"
fi

echo "> Wget binary found at: '${WGET}'"

if ! command -v 7z 1> /dev/null 2>&1; then
    if [ -n "${P7ZIP_FALLBACK}" ]; then
        P7ZIP="${P7ZIP_FALLBACK}"
    else
        echo "> Unable to find 7z from your environment's PATH variable."
        echo '> Aborting.'
        exit 1
    fi
else
    P7ZIP="$(command -v 7z 2> /dev/null)"
fi

echo "> 7z binary found at: '${P7ZIP}'"

if ! command -v 7z 1> /dev/null 2>&1; then
    echo "> Unable to find 7z from your environment's PATH variable."
    echo '> Aborting.'
    exit 1
fi

if ! command -v binarycreator 1> /dev/null 2>&1; then
    if [ -n "${BINARYCREATOR_FALLBACK}" ]; then
        BINARYCREATOR="${BINARYCREATOR_FALLBACK_FALLBACK}"
    else
        echo "> Unable to find binarycreator from your environment's PATH variable."
        echo '> Aborting.'
        exit 1
    fi
else
    BINARYCREATOR="$(command -v binarycreator 2> /dev/null)"
fi

echo "> BinaryCreator binary found at: '${BINARYCREATOR}'"

if ! command -v upx 1> /dev/null 2>&1; then
    if [ -n "${UPX_FALLBACK}" ]; then
        UPX="${UPX_FALLBACK}"
        echo "> UPX binary found at: '${UPX}'"
    else
        if [ "${COMPRESS_INSTALLER_IF_POSSIBLE}" = '1' ]; then
            echo "> Unable to find upx from your environment's PATH variable."
            echo '> Compressing the installer will be skipped.'
        fi

        COMPRESS_INSTALLER_IF_POSSIBLE=0
    fi
else
    UPX="$(command -v upx 2> /dev/null)"
    echo "> UPX binary found at: '${UPX}'"
fi

TEST_MEDIA
CLEAR_DATA_OUTPUT_DIRS
EXPAND_MEDIA
MERGE_SUBDIRECTORY_TO_ROOT 'GAME'
MERGE_SUBDIRECTORY_TO_ROOT 'DATA'
MERGE_SUBDIRECTORY_TO_ROOT 'FONTS'
MOVE_MOVIES_TO_SEPARATE_PACKAGE
REMOVE_USELESS_FILES
RENAME_FILES
IMPORT_PATCH
IMPORT_EDITOR
IMPORT_SAMPLES
IMPORT_CUSTOM_LEVEL_FORKLAND
IMPORT_CUSTOM_LEVEL_DIRTLAND
CONVERT_BINARIES
BUILD_INSTALLER
COMPRESS_INSTALLER
CLEAR_DATA_OUTPUT_DIRS

