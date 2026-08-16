#!/bin/zsh
set -euo pipefail

repository_root="${0:A:h:h}"
output_root="${repository_root}/build"
app_bundle="${output_root}/DSH Launcher.app"
contents="${app_bundle}/Contents"

swift build --package-path "${repository_root}" -c release
binary_directory="$(swift build --package-path "${repository_root}" -c release --show-bin-path)"

rm -rf "${app_bundle}"
mkdir -p "${contents}/MacOS" "${contents}/Resources"
cp "${binary_directory}/DSHLauncher" "${contents}/MacOS/DSHLauncher"
cp "${repository_root}/Resources/Info.plist" "${contents}/Info.plist"

if [[ -n "${DSH_NODE_RUNTIME:-}" ]]; then
    if [[ ! -x "${DSH_NODE_RUNTIME}/bin/node" || ! -x "${DSH_NODE_RUNTIME}/bin/npm" ]]; then
        print -u2 "DSH_NODE_RUNTIME must contain executable bin/node and bin/npm"
        exit 1
    fi
    ditto "${DSH_NODE_RUNTIME}" "${contents}/Resources/runtime"
fi

codesign --force --sign "${CODE_SIGN_IDENTITY:--}" "${app_bundle}"
print "Created ${app_bundle}"
