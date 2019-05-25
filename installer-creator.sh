#!/usr/bin/env sh

EXCLUDE_MOVIES=0

CRACK_BINARIES_IF_POSSIBLE=1
COMPRESS_INSTALLER_IF_POSSIBLE=0

P7ZIP_FALLBACK=''
BINARYCREATOR_FALLBACK=''
UPX_FALLBACK=''

RELATIVE_PATH=$(dirname ${0})
MEDIA="${RELATIVE_PATH}/gruntz.iso"

if [[ ! -z "${1}" ]]; then
    MEDIA="${1}"
fi

GRUNTZ_DATA_OUTPUT_DIR="packages/eu.murda.gruntz/data"
GRUNTZ_DATA_MOVIES_OUTPUT_DIR='packages/eu.murda.gruntz.movies/data'

PATCH_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.patch/data'

EDITOR_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.editor.editor/data'
SAMPLES_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.editor.samples/data/CUSTOM'

CUSTOM_LEVEL_FORKLAND_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.custom.battles.forkland/data/CUSTOM'
CUSTOM_LEVEL_DIRTLAND_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.custom.battles.dirtland/data/CUSTOM'

PATCH_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-patch.zip'
PATCH_ARCHIVE_NAME="tmp/$(basename ${PATCH_DOWNLOAD_URL})"

EDITOR_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-editor.zip'
EDITOR_ARCHIVE_NAME="tmp/$(basename ${EDITOR_DOWNLOAD_URL})"

SAMPLES_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-sample-levels.zip'
SAMPLES_ARCHIVE_NAME="tmp/$(basename ${SAMPLES_DOWNLOAD_URL})"

CUSTOM_LEVEL_FORKLAND_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-forkland.zip'
CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME="tmp/$(basename ${CUSTOM_LEVEL_FORKLAND_DOWNLOAD_URL})"

CUSTOM_LEVEL_DIRTLAND_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-dirtland.zip'
CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME="tmp/$(basename ${CUSTOM_LEVEL_DIRTLAND_DOWNLOAD_URL})"

TEST_MEDIA () {
    if [[ ! -f "${MEDIA}" ]]; then
        echo "> Specified ISO file doesn't exist on your filesystem."
        echo '> Aborting.'
        exit 1
    fi

    VALID_HASH_FOUND=0

    for VALID_HASH in \
        '275547756A472DA85298F7B86FBAF197'
    do
        MEDIA_HASH="$(md5sum ${MEDIA} | cut -d ' ' -f 1)"

        if [[ "${VALID_HASH}" = "${MEDIA_HASH^^}" ]]; then
            VALID_HASH_FOUND=1
            break
        fi
    done

    if [[ "${VALID_HASH_FOUND}" != '1' ]]; then
        echo "> Specified ISO file doesn't match with required fingerprint."
        echo '> Aborting.'
        exit 1
    fi
}

CLEAR_DATA_OUTPUT_DIRS () {
    for DIR_TO_CLEAR in $(find "${RELATIVE_PATH}" -type d -name 'data')
    do
        rm -r "${DIR_TO_CLEAR}/"*
    done
}

EXPAND_MEDIA () {
    "${P7ZIP}" x -aoa "-o${GRUNTZ_DATA_OUTPUT_DIR}" "${MEDIA}"
}

MERGE_SUBDIRECTORY_TO_ROOT () {
    if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/${1}" ]]; then
        mv "${GRUNTZ_DATA_OUTPUT_DIR}/${1}/"* "${GRUNTZ_DATA_OUTPUT_DIR}"
        rm -r "${GRUNTZ_DATA_OUTPUT_DIR}/${1}"
    fi
}

DELETE_USELESS_FILES () {
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
        if [[ -f "${GRUNTZ_DATA_OUTPUT_DIR}/${USELESS_FILE}" ]]; then
            rm "${GRUNTZ_DATA_OUTPUT_DIR}/${USELESS_FILE}"
        fi

        if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/${USELESS_FILE}" ]]; then
            rm -r "${GRUNTZ_DATA_OUTPUT_DIR}/${USELESS_FILE}"
        fi
    done
}

MOVE_MOVIES_TO_SEPARATE_PACKAGE () {
    if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/MOVIEZ" ]]; then
        mv "${GRUNTZ_DATA_OUTPUT_DIR}/MOVIEZ" "${GRUNTZ_DATA_MOVIES_OUTPUT_DIR}"
    fi
}

IMPORT_PATCH () {
    if [[ ! -f "${PATCH_ARCHIVE_NAME}" ]]; then
        wget "${PATCH_DOWNLOAD_URL}" -O "${PATCH_ARCHIVE_NAME}"
    fi

    if [[ -f "${PATCH_ARCHIVE_NAME}" ]]; then
        "${P7ZIP}" x -aoa "-o${PATCH_DATA_OUTPUT_DIR}" "${PATCH_ARCHIVE_NAME}"
    fi
}

IMPORT_EDITOR () {
    if [[ ! -f "${EDITOR_ARCHIVE_NAME}" ]]; then
        wget "${EDITOR_DOWNLOAD_URL}" -O "${EDITOR_ARCHIVE_NAME}"
    fi

    if [[ -f "${EDITOR_ARCHIVE_NAME}" ]]; then
        "${P7ZIP}" x -aoa "-o${EDITOR_DATA_OUTPUT_DIR}" "${EDITOR_ARCHIVE_NAME}"
    fi
}

IMPORT_SAMPLES () {
    if [[ ! -f "${SAMPLES_ARCHIVE_NAME}" ]]; then
        wget "${SAMPLES_DOWNLOAD_URL}" -O "${SAMPLES_ARCHIVE_NAME}"
    fi

    if [[ -f "${SAMPLES_ARCHIVE_NAME}" ]]; then
        "${P7ZIP}" x -aoa "-o${SAMPLES_DATA_OUTPUT_DIR}" "${SAMPLES_ARCHIVE_NAME}"
    fi
}

IMPORT_CUSTOM_LEVEL_FORKLAND () {
    if [[ ! -f "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}" ]]; then
        wget "${CUSTOM_LEVEL_FORKLAND_DOWNLOAD_URL}" -O "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}"
    fi

    if [[ -f "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}" ]]; then
        "${P7ZIP}" x -aoa "-o${CUSTOM_LEVEL_FORKLAND_DATA_OUTPUT_DIR}" "${CUSTOM_LEVEL_FORKLAND_ARCHIVE_NAME}"
    fi
}

IMPORT_CUSTOM_LEVEL_DIRTLAND () {
    if [[ ! -f "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}" ]]; then
        wget "${CUSTOM_LEVEL_DIRTLAND_DOWNLOAD_URL}" -O "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}"
    fi

    if [[ -f "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}" ]]; then
        "${P7ZIP}" x -aoa "-o${CUSTOM_LEVEL_DIRTLAND_DATA_OUTPUT_DIR}" "${CUSTOM_LEVEL_DIRTLAND_ARCHIVE_NAME}"
    fi
}

REPLACE_BYTE () {
    printf "$(printf '\\x%02X' ${3})" | dd of="${1}" bs=1 seek=${2} count=1 conv=notrunc 1> /dev/null
}

BUILD_INSTALLER () {
    COMMAND="${BINARYCREATOR} --offline-only -c config/config.xml -p packages"
    COMMAND="${COMMAND} -e eu.murda.gruntz.ddraw"
    [[ "${EXCLUDE_MOVIES}" == 0 ]] || COMMAND="${COMMAND} -e eu.murda.gruntz.movies"
    COMMAND="${COMMAND} GruntzInstaller"
    eval "${COMMAND}"
}

which 7z 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    if [[ ! -z "${P7ZIP_FALLBACK}" ]]; then
        P7ZIP="${P7ZIP_FALLBACK}"
    else
        echo "> Unable to find 7z from your environment's PATH variable."
        echo '> Aborting.'
        exit 1
    fi
else
    P7ZIP="$(which 7z)"
fi

echo "> 7z binary found at: '${P7ZIP}'"

which 7z 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    echo "> Unable to find 7z from your environment's PATH variable."
    echo '> Aborting.'
    exit 1
fi

which binarycreator 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    if [[ ! -z "${BINARYCREATOR_FALLBACK}" ]]; then
        BINARYCREATOR="${BINARYCREATOR_FALLBACK_FALLBACK}"
    else
        echo "> Unable to find binarycreator from your environment's PATH variable."
        echo '> Aborting.'
        exit 1
    fi
else
    BINARYCREATOR="$(which binarycreator)"
fi

echo "> BinaryCreator binary found at: '${BINARYCREATOR}'"

TEST_MEDIA
CLEAR_DATA_OUTPUT_DIRS
EXPAND_MEDIA
MERGE_SUBDIRECTORY_TO_ROOT 'GAME'
MERGE_SUBDIRECTORY_TO_ROOT 'DATA'
MERGE_SUBDIRECTORY_TO_ROOT 'FONTS'
MOVE_MOVIES_TO_SEPARATE_PACKAGE
DELETE_USELESS_FILES
IMPORT_PATCH
IMPORT_EDITOR
IMPORT_SAMPLES
IMPORT_CUSTOM_LEVEL_FORKLAND
IMPORT_CUSTOM_LEVEL_FORKLAND
BUILD_INSTALLER
