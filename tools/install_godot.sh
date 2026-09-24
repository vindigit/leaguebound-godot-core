#!/usr/bin/env bash
# Install the Godot editor build pinned by this repository.
#
# The engine version is pinned in three places that must agree:
#   - README.md "Technical baseline"
#   - project.godot [simulation] engine_version
#   - GODOT_VERSION below
#
# Downloads are verified against the SHA-512 digests published by the Godot
# project in the SHA512-SUMS.txt asset of the godotengine/godot-builds release.
# A digest mismatch is fatal: the archive is discarded and nothing is installed.
#
# Idempotent. Prints the absolute path of the installed binary on stdout; all
# progress reporting goes to stderr so the path can be captured directly:
#
#   GODOT_BIN="$(tools/install_godot.sh)"

set -euo pipefail

GODOT_VERSION="4.7.1"
GODOT_FLAVOR="stable"
GODOT_TAG="${GODOT_VERSION}-${GODOT_FLAVOR}"

# Published SHA-512 of each release archive, keyed by Godot's platform slug.
declare -A GODOT_ARCHIVE_SHA512=(
	[linux.x86_64]="4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9"
	[linux.arm64]="de64efe4d936ac0403769e078a73d961a9c647cab04168c5fb5a7fe33728e200a67324ed99368eeb27964e205e72a61e48efb63b52d5de34d12dd6a95ca0fc45"
	[linux.x86_32]="8d980dc6919b9002545155a010285ac0d0746b4128f81536f3a409206cb4ad3a6398247d43f5df2de697c190ae1bc3b1b57e28263f6ba93c80a9f4b0155b1387"
	[linux.arm32]="276bca6f8dbaade1220336eb44259e3f423e1027a8a3d35422d8d8129a208220cbccef48f63dc5f0cd52fe96c7d3d39bf34143d29635e5fcdbe744fda1bb933b"
)

log() { printf 'install_godot: %s\n' "$*" >&2; }
die() { printf 'install_godot: error: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || die "only Linux hosts are supported; got $(uname -s)"

case "$(uname -m)" in
	x86_64 | amd64) platform="linux.x86_64" ;;
	aarch64 | arm64) platform="linux.arm64" ;;
	i386 | i686) platform="linux.x86_32" ;;
	armv7l | armv7) platform="linux.arm32" ;;
	*) die "unsupported architecture $(uname -m)" ;;
esac

archive="Godot_v${GODOT_TAG}_${platform}.zip"
expected_sha512="${GODOT_ARCHIVE_SHA512[$platform]}"

install_root="${GODOT_INSTALL_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/godot}"
install_dir="${install_root}/${GODOT_TAG}/${platform}"
binary="${install_dir}/Godot_v${GODOT_TAG}_${platform}"

if [ -x "$binary" ] && "$binary" --version 2>/dev/null | grep -q "^${GODOT_VERSION}\.${GODOT_FLAVOR}"; then
	log "already installed at ${binary}"
	printf '%s\n' "$binary"
	exit 0
fi

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v unzip >/dev/null 2>&1 || die "unzip is required"
command -v sha512sum >/dev/null 2>&1 || die "sha512sum is required"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# The redirector is the canonical entry point; the release asset is the fallback
# for networks that cannot follow it. Both serve the same signed archive.
mirrors=(
	"https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=${GODOT_FLAVOR}&slug=${platform}.zip&platform=${platform}"
	"https://github.com/godotengine/godot-builds/releases/download/${GODOT_TAG}/${archive}"
)

downloaded=""
for mirror in "${mirrors[@]}"; do
	log "downloading ${archive}"
	if curl --fail --location --silent --show-error --retry 3 --retry-delay 2 \
		--max-time 900 --output "${workdir}/${archive}" "$mirror"; then
		downloaded="yes"
		break
	fi
	log "mirror failed, trying next"
done
[ -n "$downloaded" ] || die "could not download ${archive} from any mirror"

actual_sha512="$(sha512sum "${workdir}/${archive}" | cut -d' ' -f1)"
if [ "$actual_sha512" != "$expected_sha512" ]; then
	rm -f "${workdir}/${archive}"
	die "SHA-512 mismatch for ${archive}
  expected ${expected_sha512}
  actual   ${actual_sha512}
The download was discarded. Do not install this archive."
fi
log "SHA-512 verified"

unzip -q -o "${workdir}/${archive}" -d "${workdir}/extracted"
extracted="$(find "${workdir}/extracted" -maxdepth 2 -type f -name "Godot_v${GODOT_TAG}_${platform}" -print -quit)"
[ -n "$extracted" ] || die "archive did not contain Godot_v${GODOT_TAG}_${platform}"

mkdir -p "$install_dir"
install -m 0755 "$extracted" "$binary"

reported="$("$binary" --version)"
case "$reported" in
	"${GODOT_VERSION}.${GODOT_FLAVOR}"*) ;;
	*) die "installed binary reports ${reported}, expected ${GODOT_VERSION}.${GODOT_FLAVOR}" ;;
esac

log "installed ${reported} at ${binary}"
printf '%s\n' "$binary"
