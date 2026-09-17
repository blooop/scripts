#!/usr/bin/env bash
# flash_ubuntu_usb.sh — Download, verify and write an Ubuntu (or flavour) ISO to a USB stick.
#
# Why: the obvious way to do this is to hardcode an ISO path and its SHA256 in a
# script, but then a new release means hand-fetching SHA256SUMS, hand-checking its
# signature and pasting a new hash in — i.e. the script automates the easy 10% and
# leaves you the error-prone 90%. So this one derives everything from the version:
# it fetches the SIGNED SHA256SUMS and takes the expected hash from there. The trust
# anchor is a pinned GPG key fingerprint, not a hash someone copied off a webpage.
#
# Two gotchas this encodes so you don't have to remember them:
#   * Main Ubuntu lives on releases.ubuntu.com; flavours live on cdimage.ubuntu.com
#     under a different path. cdimage also carries unreleased dev trees, so a naive
#     URL template can hand you a nightly.
#   * Point releases only exist for LTS. 24.04 has .1-.5 (and a .5.1); 25.10 has none
#     and never will. There is no such thing as "27.04.0" — an interim release is
#     just "27.04".
#
# Run with: ./flash_ubuntu_usb.sh ubuntu 26.04.1 /dev/sda
#           ./flash_ubuntu_usb.sh xubuntu 26.04.1 /dev/sda --variant minimal
#           ./flash_ubuntu_usb.sh ubuntu 26.04.1 /dev/sda --dry-run   (verify only)
# Needs sudo only for the write; the download and verify run unprivileged.
set -euo pipefail

# Ubuntu CD Image Automatic Signing Key (2012). Ships in the archive keyring on
# every Ubuntu box. Pinning the fingerprint is what makes a keyserver fallback safe.
KEY_FPR="843938DF228D22F7B3742BC0D94AA3F0EFE21092"
LOCAL_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

VARIANT="desktop"
ARCH="amd64"
ISO_DIR="${FLASH_ISO_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/ubuntu-isos}"
DRY_RUN=0

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
    cat >&2 <<'USAGE'
Usage: flash_ubuntu_usb.sh <flavour> <version> <device> [options]

  flavour   ubuntu, xubuntu, kubuntu, lubuntu, ubuntu-mate, ubuntu-budgie, ...
  version   e.g. 26.04.1 (LTS point release) or 27.04 (interim — no .0 suffix)
  device    whole USB disk, e.g. /dev/sda

Options:
  --variant <v>  desktop (default), live-server, minimal
  --arch <a>     amd64 (default), arm64, riscv64
  --dir <path>   where to cache ISOs (default: ~/.cache/ubuntu-isos)
  --dry-run      download and verify, but do not write to the device
  --keep         keep the ISO after a successful write (default: keep)
USAGE
    exit 2
}

# ─── 1. Arguments ──────────────────────────────────────────────────────────────
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --variant) VARIANT="${2:?--variant needs a value}"; shift 2 ;;
        --arch)    ARCH="${2:?--arch needs a value}";       shift 2 ;;
        --dir)     ISO_DIR="${2:?--dir needs a value}";     shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --keep)    shift ;;
        -h|--help) usage ;;
        -*)        die "unknown option: $1" ;;
        *)         POSITIONAL+=("$1"); shift ;;
    esac
done
[[ ${#POSITIONAL[@]} -eq 3 ]] || usage
FLAVOUR="${POSITIONAL[0]}"
VERSION="${POSITIONAL[1]}"
DEV="${POSITIONAL[2]}"

[[ $VERSION =~ ^[0-9]{2}\.[0-9]{2}(\.[0-9]+)*$ ]] || die "version '$VERSION' doesn't look like 26.04.1 or 27.04"
if [[ $VERSION =~ \.0$ ]]; then
    die "'$VERSION' is almost certainly wrong — releases have no .0 suffix.
  An interim release is '${VERSION%.0}'; LTS point releases start at .1"
fi

# Main Ubuntu and the flavours are published to different hosts and layouts.
if [[ $FLAVOUR == "ubuntu" ]]; then
    BASE_URL="https://releases.ubuntu.com/${VERSION}"
else
    BASE_URL="https://cdimage.ubuntu.com/${FLAVOUR}/releases/${VERSION}/release"
fi
ISO_NAME="${FLAVOUR}-${VERSION}-${VARIANT}-${ARCH}.iso"
ISO_PATH="${ISO_DIR}/${ISO_NAME}"

SUDO=()
[[ $EUID -eq 0 ]] || SUDO=(sudo)

echo "=== Plan ==="
echo "  image:  $ISO_NAME"
echo "  source: $BASE_URL"
echo "  cache:  $ISO_DIR"
echo "  target: $DEV$([[ $DRY_RUN -eq 1 ]] && echo "  (DRY RUN — will not be written)")"
echo ""

# ─── 2. Check the target BEFORE downloading several GB ─────────────────────────
# Fail fast: a bad device argument should cost you a second, not a 6 GB download.
echo "=== 1. Checking target device ==="
if [[ $DRY_RUN -eq 0 ]]; then
    [[ -b $DEV ]] || die "not a block device: $DEV"
    base=$(basename "$DEV")
    [[ -e /sys/block/$base ]] || die "$DEV is a partition, not a whole disk — pass e.g. /dev/sda"

    # The guard that stops a typo from eating an internal drive.
    tran=$(lsblk -dno TRAN "$DEV")
    removable=$(cat "/sys/block/$base/removable")
    [[ $tran == "usb" ]]    || die "$DEV transport is '$tran', not usb — refusing"
    [[ $removable == "1" ]] || die "$DEV is not flagged removable — refusing"

    # Refuse if anything on this disk holds a system mount.
    while read -r part mnt; do
        case "$mnt" in
            ""|/media/*|/mnt/*|/run/media/*) ;;
            *) die "$part is mounted at $mnt — that looks like a system disk, refusing" ;;
        esac
    done < <(lsblk -nro NAME,MOUNTPOINT "$DEV" | awk '{print "/dev/"$1, $2}')

    echo "  $DEV — $(lsblk -dno SIZE,MODEL "$DEV") — removable USB disk, OK"

    # Prime sudo now so it doesn't prompt after a long download.
    "${SUDO[@]}" -v 2>/dev/null || true
else
    echo "  skipped (dry run)"
fi
echo ""

# ─── 3. Fetch and verify the signed checksum file ──────────────────────────────
echo "=== 2. Fetching signed checksums ==="
mkdir -p "$ISO_DIR"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if ! curl -fsSL --max-time 120 -o "$WORK/SHA256SUMS" "$BASE_URL/SHA256SUMS"; then
    echo "Could not fetch $BASE_URL/SHA256SUMS" >&2
    echo "Versions published for '$FLAVOUR':" >&2
    if [[ $FLAVOUR == "ubuntu" ]]; then
        curl -fsSL --max-time 60 "https://releases.ubuntu.com/" 2>/dev/null \
            | grep -oE 'href="[0-9]{2}\.[0-9]{2}[0-9.]*/"' | tr -d 'href="/' | sort -uV | tr '\n' ' ' >&2
    else
        curl -fsSL --max-time 60 "https://cdimage.ubuntu.com/${FLAVOUR}/releases/" 2>/dev/null \
            | grep -oE 'href="[0-9]{2}\.[0-9]{2}[0-9.]*/"' | tr -d 'href="/' | sort -uV | tr '\n' ' ' >&2
    fi
    echo "" >&2
    die "no such release directory"
fi
curl -fsSL --max-time 120 -o "$WORK/SHA256SUMS.gpg" "$BASE_URL/SHA256SUMS.gpg" \
    || die "checksums are published but the signature is not — refusing to trust them"

# Verify against the pinned key only. Note that a bare `gpg --verify` exits 0 for
# ANY key in the user's keyring, so the fingerprint check below is the real test.
if [[ -r $LOCAL_KEYRING ]] && gpg --no-default-keyring --keyring "$LOCAL_KEYRING" \
        --list-keys "$KEY_FPR" >/dev/null 2>&1; then
    KEYRING="$LOCAL_KEYRING"
    echo "  using OS keyring: $LOCAL_KEYRING"
else
    KEYRING="$WORK/pinned.gpg"
    echo "  key not in OS keyring, fetching from keyserver (fingerprint is pinned)..."
    gpg --no-default-keyring --keyring "$KEYRING" --keyserver keyserver.ubuntu.com \
        --recv-keys "$KEY_FPR" >/dev/null 2>&1 || die "could not obtain signing key $KEY_FPR"
fi

# VALIDSIG carries both the signing key and its primary key fingerprint, so this
# still matches if Canonical ever signs with a subkey of the same primary key.
gpg --no-default-keyring --keyring "$KEYRING" --status-fd 1 --verify \
    "$WORK/SHA256SUMS.gpg" "$WORK/SHA256SUMS" 2>/dev/null \
    | grep -q "^\[GNUPG:\] VALIDSIG .*${KEY_FPR}" \
    || die "SHA256SUMS is NOT signed by the pinned Ubuntu CD Image key ($KEY_FPR)"
echo "  signature OK — signed by $KEY_FPR"

WANT=$(awk -v f="$ISO_NAME" '$2 == "*" f || $2 == f {print $1}' "$WORK/SHA256SUMS")
if [[ -z $WANT ]]; then
    echo "'$ISO_NAME' is not in the signed checksum file. It lists:" >&2
    awk '{print "  " $2}' "$WORK/SHA256SUMS" | tr -d '*' >&2
    die "no such image — check --variant and --arch"
fi
echo "  expected sha256: $WANT"
echo ""

# ─── 4. Download (resumable, skipped if we already have it) ────────────────────
echo "=== 3. Obtaining the ISO ==="
if [[ -f $ISO_PATH ]] && [[ $(sha256sum "$ISO_PATH" | cut -d' ' -f1) == "$WANT" ]]; then
    echo "  already cached and verified: $ISO_PATH"
else
    echo "  downloading $BASE_URL/$ISO_NAME"
    curl -fL --progress-bar -C - -o "$ISO_PATH" "$BASE_URL/$ISO_NAME" \
        || die "download failed"
    echo "  verifying..."
    got=$(sha256sum "$ISO_PATH" | cut -d' ' -f1)
    [[ $got == "$WANT" ]] || die "checksum mismatch after download
  expected $WANT
  got      $got
  (delete $ISO_PATH and retry)"
    echo "  sha256 OK"
fi
ISO_BYTES=$(stat -c%s "$ISO_PATH")
echo "  $ISO_PATH  ($(numfmt --to=iec "$ISO_BYTES"))"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
    echo "=== Dry run complete — image verified, device untouched. ==="
    exit 0
fi

# ─── 5. Write ──────────────────────────────────────────────────────────────────
echo "=== 4. Writing to $DEV ==="
echo "This ERASES EVERYTHING on $DEV:"
lsblk -o NAME,SIZE,LABEL,MOUNTPOINT "$DEV" | sed 's/^/  /'
echo ""
read -rp "Type the device name to confirm ($DEV): " ans
[[ $ans == "$DEV" ]] || die "not confirmed"

for p in $(lsblk -nro NAME "$DEV" | tail -n +2); do
    if findmnt -no TARGET "/dev/$p" >/dev/null 2>&1; then
        "${SUDO[@]}" umount "/dev/$p" && echo "  unmounted /dev/$p"
    fi
done

"${SUDO[@]}" dd if="$ISO_PATH" of="$DEV" bs=4M conv=fsync oflag=direct status=progress
"${SUDO[@]}" sync
echo ""

# ─── 6. Verify what actually landed ────────────────────────────────────────────
# Reading the bytes back is the only way to catch a stick that accepted the write
# and quietly stored something else.
echo "=== 5. Verifying the stick ==="
"${SUDO[@]}" blockdev --flushbufs "$DEV"
dev_sum=$("${SUDO[@]}" head -c "$ISO_BYTES" "$DEV" | sha256sum | cut -d' ' -f1)
[[ $dev_sum == "$WANT" ]] || die "read-back mismatch: got $dev_sum — the write did not land cleanly"
echo "  OK — $DEV matches the ISO."

"${SUDO[@]}" partprobe "$DEV" 2>/dev/null || true
echo ""
echo "=== Done ==="
echo "$DEV is now a $FLAVOUR $VERSION $VARIANT installer."
echo "The ISO is cached at $ISO_PATH — delete it if you want the space back."
