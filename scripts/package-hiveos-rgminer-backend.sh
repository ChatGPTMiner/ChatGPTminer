#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/rgminer-hiveos.tar.gz" >&2
  exit 64
fi

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_archive="$1"
version="0.3.5"
package_name="chatgptminer-${version}"
output="$project_dir/dist/${package_name}.tar.gz"
stage="$(mktemp -d)"
unpack="$stage/unpack"
package="$stage/package"
trap 'rm -rf "$stage"' EXIT

[[ -f "$source_archive" ]] || { echo "Archive not found: $source_archive" >&2; exit 1; }
mkdir -p "$unpack" "$package" "$project_dir/dist"
python3 - "$source_archive" "$unpack" <<'PY'
import pathlib, sys, tarfile
archive, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
with tarfile.open(archive, "r:gz") as tf:
    members = tf.getmembers()
    for member in members:
        path = pathlib.PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts or member.issym() or member.islnk():
            raise SystemExit(f"unsafe archive member: {member.name}")
    tf.extractall(out, filter="data")
PY

source_root="$(find "$unpack" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[[ -n "$source_root" && -x "$source_root/rgminer" && -f "$source_root/h-run.sh" ]] || {
  echo "Input is not a supported rgminer HiveOS package" >&2
  exit 1
}
cp -a "$source_root/." "$package/"
mv "$package/h-run.sh" "$package/h-run-rgminer.sh"
install -m 0755 "$project_dir/hiveos/h-run-rgminer-backend.sh" "$package/h-run.sh"
chmod 0755 "$package"
chmod 0755 "$package/rgminer" "$package/h-run-rgminer.sh" \
  "$package/h-config.sh" "$package/h-stats.sh" "$package/h-driver.sh"
cat >"$package/h-manifest.conf" <<EOF
CUSTOM_NAME=${package_name}
CUSTOM_VERSION=${version}
CUSTOM_CONFIG_FILENAME=/hive/miners/custom/config.env
CUSTOM_LOG_BASENAME=/var/log/miner/custom/chatgptminer
CUSTOM_API_PORT=9200
EOF
cat >"$package/CHATGPTMINER_BACKEND_NOTICE.txt" <<EOF
ChatGPTminer ${version} HiveOS transition package

The executable and original HiveOS integration files came from the operator-
supplied rgminer 1.1.3b archive. SHA-256 of the supplied archive:
$(sha256sum "$source_archive" | awk '{print $1}')

ChatGPTminer adds a visible 2% wallet schedule (2940 seconds user, 60 seconds
developer). The rgminer backend may apply its own upstream fee or terms.
This package does not represent the rgminer binary as ChatGPTminer source code.
EOF

find "$package" -type d -exec chmod 0755 {} +
find "$package" -type f ! -perm /111 -exec chmod 0644 {} +
tar --owner=0 --group=0 --numeric-owner -C "$package" -czf "$output" .
sha256sum "$output" >"$output.sha256"
printf '%s\n' "$output"
