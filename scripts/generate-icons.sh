#!/bin/zsh
set -euo pipefail

repository_root="${0:A:h:h}"
source_directory="${repository_root}/Sources/DSHLauncher/Resources"
output_directory="${repository_root}/Resources"
working_directory="${repository_root}/build/AppIcon.iconset"
source_png="${source_directory}/AppIconSource.png"

rm -rf "${working_directory}"
mkdir -p "${working_directory}" "${output_directory}"

for size in 16 32 128 256 512; do
    sips -z "${size}" "${size}" "${source_png}" --out "${working_directory}/icon_${size}x${size}.png" >/dev/null
    retina_size=$((size * 2))
    sips -z "${retina_size}" "${retina_size}" "${source_png}" --out "${working_directory}/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "${working_directory}" -o "${output_directory}/AppIcon.icns"
print "Created ${output_directory}/AppIcon.icns"
