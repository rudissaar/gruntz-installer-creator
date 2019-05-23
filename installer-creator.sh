#!/usr/bin/env sh

EXCLUDE_MOVIES=0

CRACK_BINARIES_IF_POSSIBLE=1
COMPRESS_INSTALLER_IF_POSSIBLE=0

P7ZIP_FALLBACK=''
BINARY_CREATOR_FALLBACK=''
UPX_FALLBACK=''

RELATIVE_PATH=$(dirname ${0})
MEDIA="${RELATIVE_PATH}/gruntz.iso"

if [[ ! -z "${1}" ]]; then
    MEDIA="${1}"
fi

GRUNTZ_DATA_OUTPUT_DIR='packages/eu.murda.gruntz/data'
GRUNTZ_DATA_MOVIES_OUTPUT_DIR='packages/eu.murda.gruntz.movies/data'

DDRAW_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.ddraw/data'
PATCH_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.patch/data'

EDITOR_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.editor.editor/data'
SAMPLES_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.editor.samples/data/CUSTOM'

CUSTOM_LEVEL_FORKLAND_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.custom.battles.forkland/data/CUSTOM'
CUSTOM_LEVEL_DIRTLAND_DATA_OUTPUT_DIR='packages/eu.murda.gruntz.custom.battles.dirtland/data/CUSTOM'

DDRAW_DOWNLOAD_URL='http://legacy.murda.eu/downloads/gruntz/gruntz-ddraw.zip'
DDRAW_ARCHIVE_NAME="tmp/$(basename ${DDRAW_DOWNLOAD_URL})"

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

which 7z 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    echo "> Unable to find 7z from your environment's PATH variable."
    echo '> Aborting.'
    exit 1
fi

P7ZIP="$(which 7z)"
echo "> 7z binary found at: '${P7ZIP}'"

which 7z 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    echo "> Unable to find 7z from your environment's PATH variable."
    echo '> Aborting.'
    exit 1
fi

BINARYCREATOR="$(which binarycreator)"
echo "> BinaryCreator binary found at: '${BINARYCREATOR}'"

if [[ "${?}" != '0' ]]; then
    echo "> Unable to find binarycreator from your environment's PATH variable."
    echo '> Aborting.'
    exit 1
fi

for DIR_TO_CLEAR in $(find "${RELATIVE_PATH}" -type d -name 'data')
do
    rm -r "${DIR_TO_CLEAR}/"*
done

"${P7ZIP}" x -aoa "-o${GRUNTZ_DATA_OUTPUT_DIR}" "${MEDIA}"

if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/GAME" ]]; then
    mv "${GRUNTZ_DATA_OUTPUT_DIR}/GAME/"* "${GRUNTZ_DATA_OUTPUT_DIR}"
    rm -r "${GRUNTZ_DATA_OUTPUT_DIR}/GAME"
fi

if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/DATA" ]]; then
    mv "${GRUNTZ_DATA_OUTPUT_DIR}/DATA/"* "${GRUNTZ_DATA_OUTPUT_DIR}"
    rm -r "${GRUNTZ_DATA_OUTPUT_DIR}/DATA"
fi

if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/FONTS" ]]; then
    mv "${GRUNTZ_DATA_OUTPUT_DIR}/FONTS/"* "${GRUNTZ_DATA_OUTPUT_DIR}"
    rm -r "${GRUNTZ_DATA_OUTPUT_DIR}/FONTS"
fi

if [[ -d "${GRUNTZ_DATA_OUTPUT_DIR}/MOVIEZ" ]]; then
    mv "${GRUNTZ_DATA_OUTPUT_DIR}/MOVIEZ" "${GRUNTZ_DATA_MOVIES_OUTPUT_DIR}"
fi

"${BINARYCREATOR}" \
    '--offline-only' \
    '-c' 'config/config.xml' \
    '-p' 'packages' \
    'GruntzInstaller'
