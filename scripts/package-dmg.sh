#!/bin/zsh
set -euo pipefail

repository_root="${0:A:h:h}"
app_bundle="${repository_root}/build/DSH Desktop.app"
output_path="${1:-${repository_root}/build/DSH Desktop.dmg}"

if [[ ! -d "${app_bundle}" ]]; then
    print -u2 "App bundle not found: ${app_bundle}"
    print -u2 "Run ./scripts/package-app.sh first."
    exit 1
fi

if [[ "${output_path}" != *.dmg ]]; then
    print -u2 "DMG output path must end in .dmg: ${output_path}"
    exit 1
fi

working_directory="$(mktemp -d "${TMPDIR:-/tmp}/dsh-desktop-dmg.XXXXXX")"
staging_directory="${working_directory}/staging"
mount_directory="${working_directory}/mount"
mounted=false

cleanup() {
    if [[ "${mounted}" == true ]]; then
        hdiutil detach "${mount_directory}" -quiet || true
    fi
    rm -rf "${working_directory}"
}
trap cleanup EXIT

mkdir -p "${staging_directory}" "${mount_directory}" "${output_path:h}"
ditto "${app_bundle}" "${staging_directory}/DSH Desktop.app"
ln -s /Applications "${staging_directory}/Applications"

hdiutil create \
    -quiet \
    -ov \
    -format UDZO \
    -fs HFS+ \
    -volname "DSH Desktop" \
    -srcfolder "${staging_directory}" \
    "${output_path}"
hdiutil verify -quiet "${output_path}"

hdiutil attach -quiet -readonly -nobrowse -mountpoint "${mount_directory}" "${output_path}"
mounted=true
test -d "${mount_directory}/DSH Desktop.app"
test "$(readlink "${mount_directory}/Applications")" = "/Applications"
hdiutil detach "${mount_directory}" -quiet
mounted=false

print "Created ${output_path}"
