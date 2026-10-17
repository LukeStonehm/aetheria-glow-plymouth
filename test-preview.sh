#!/usr/bin/env bash
# Temporary local-VT preview. No theme selection, boot rebuild, or LUKS access.
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
if (( EUID != 0 )); then
    echo 'Run from a local text VT: sudo bash ./test-preview.sh' >&2
    exit 1
fi
for tool in plymouth plymouthd unshare mount umount mountpoint timeout pgrep tty stty mktemp install readlink; do
    command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done
vt=$(tty) || { echo 'A local text VT is required.' >&2; exit 1; }
if [[ ! $vt =~ ^/dev/tty[0-9]+$ ]]; then
    echo 'Switch to a local text VT (for example Ctrl+Alt+F3), log in, then retry.' >&2
    exit 1
fi
if timeout --kill-after=1s 3s plymouth --ping >/dev/null 2>&1 || pgrep -x plymouthd >/dev/null; then
    echo 'An existing Plymouth daemon was found. This test will not touch it.' >&2
    exit 1
fi
theme_dir=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)
for name in aetheria-glow.plymouth aetheria-glow.script background.png inner-glow.png panel.png; do
    [[ -f "$theme_dir/$name" && ! -L "$theme_dir/$name" ]] || { echo "Missing regular asset: $name" >&2; exit 1; }
done
[[ -d /usr/share/plymouth/themes ]] || { echo 'Install the distro Plymouth package first; do not rebuild boot images yet.' >&2; exit 1; }
help=$(plymouthd --help 2>&1)
for option in kernel-command-line no-daemon no-boot-log pid-file tty; do
    [[ $help == *"--$option"* ]] || { echo "Installed plymouthd lacks --$option; stop and check its documentation." >&2; exit 1; }
done
echo 'Save desktop work first. This preview temporarily takes over this VT.'
echo 'Use invented input only, such as dummy-test. Never enter your real passphrase.'
echo 'First dummy submission is rejected; the second is accepted (no disk is accessed).'
echo 'Try backspace, a long input, and Esc twice to switch to details and back.'
echo 'A second dummy question is unmasked. Each request expires after 40 seconds.'
echo 'The entire preview stops after 120 seconds. Another VT: sudo plymouth quit'
read -r -p 'Type PREVIEW to start: ' answer
[[ $answer == PREVIEW ]] || exit 0
saved_stty=$(stty -g < "$vt")

# Bind mounts below exist ONLY in this new, private mount namespace. Existing
# themes remain available through a temporary read-only bind for fallback.
exec timeout --kill-after=5s 120s unshare --mount --propagation private bash -s -- "$theme_dir" "$vt" "$saved_stty" <<'PRIVATE_PREVIEW'
set -euo pipefail
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
theme_dir=$1
vt=$2
saved_stty=$3
stage=$(mktemp -d /tmp/aetheria-preview.XXXXXXXX)
daemon_pid=
theme_mounted=0
client() { timeout --kill-after=1s 3s plymouth "$@"; }
cleanup() {
    trap - EXIT INT TERM HUP
    # Only stop the daemon created by this preview.
    if [[ -n $daemon_pid ]] && kill -0 "$daemon_pid" 2>/dev/null; then
        timeout --kill-after=1s 3s plymouth quit >/dev/null 2>&1 || true
        kill "$daemon_pid" 2>/dev/null || true
        sleep 0.2
        kill -KILL "$daemon_pid" 2>/dev/null || true
        wait "$daemon_pid" 2>/dev/null || true
    fi
    stty "$saved_stty" < "$vt" 2>/dev/null || true
    printf '\033[0m\033[?25h' > "$vt" || true
    # Never recursively delete through a mount if an unmount failed.
    if (( theme_mounted )); then umount /usr/share/plymouth/themes || true; fi
    if mountpoint -q "$stage/base"; then umount "$stage/base" || true; fi
    if ! mountpoint -q "$stage/base"; then rm -rf -- "$stage"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'echo "Preview stopped or timed out." >&2; exit 124' TERM HUP
mkdir "$stage/base" "$stage/themes"
mount --bind /usr/share/plymouth/themes "$stage/base"
mount -o remount,bind,ro "$stage/base"
for existing in "$stage/base"/*; do
    [[ -e $existing ]] || continue
    [[ ${existing##*/} == aetheria-glow ]] && continue
    ln -s -- "$existing" "$stage/themes/${existing##*/}"
done
mkdir "$stage/themes/aetheria-glow"
for name in aetheria-glow.plymouth aetheria-glow.script background.png inner-glow.png panel.png; do
    install -m 644 -- "$theme_dir/$name" "$stage/themes/aetheria-glow/$name"
done
mount --bind "$stage/themes" /usr/share/plymouth/themes
theme_mounted=1
mount -o remount,bind,ro /usr/share/plymouth/themes

# The fake command line affects this daemon only; the real boot configuration
# and the selected default theme are never written.
plymouthd --no-daemon --mode=boot --tty="$vt" --no-boot-log \
    --pid-file="$stage/plymouthd.pid" \
    --kernel-command-line='splash plymouth.splash=aetheria-glow plymouth.nolog' \
    > "$stage/daemon.log" 2>&1 &
daemon_pid=$!
for ((attempt=0; attempt<50; attempt++)); do
    kill -0 "$daemon_pid" 2>/dev/null || { echo 'Preview daemon failed to start.' >&2; exit 1; }
    if client --ping >/dev/null 2>&1; then break; fi
    sleep 0.1
done
client --ping >/dev/null 2>&1 || { echo 'Preview daemon did not respond.' >&2; exit 1; }
client show-splash
sleep 3
client display-message --text='DUMMY TEST ONLY - no disk unlock. Esc toggles text details.'

# Consume and discard stdin. Accept on the second invocation, independent of
# what was typed. No passphrase reaches arguments, files, terminal, or logs.
cat > "$stage/dummy-check" <<'DUMMY_CHECK'
#!/bin/sh
cat > /dev/null
if [ -f "$0.accept-next" ]; then : > "$0.accepted"; exit 0; fi
: > "$0.accept-next"
exit 1
DUMMY_CHECK
chmod 700 "$stage/dummy-check"
result=0
timeout --kill-after=2s 40s plymouth ask-for-password \
    --prompt='Dummy encrypted-disk prompt: use invented input only. First entry is rejected; second is accepted. Backspace and Escape should work.' \
    --number-of-tries=2 --command="$stage/dummy-check" >/dev/null 2>&1 || result=$?
if (( result != 0 )); then
    echo "Dummy password test ended with status $result (124 means timeout)." >&2
    exit "$result"
fi
if ! kill -0 "$daemon_pid" 2>/dev/null || ! client --ping >/dev/null 2>&1 || [[ ! -f "$stage/dummy-check.accepted" ]]; then
    echo 'The dummy test did not complete with a responding preview daemon.' >&2
    exit 1
fi
client hide-message --text='DUMMY TEST ONLY - no disk unlock. Esc toggles text details.'
timeout --kill-after=2s 40s plymouth ask-question \
    --prompt='Unmasked dummy question: type a word, then Enter.' \
    --command=/usr/bin/cat >/dev/null 2>&1
client display-message --text='Preview complete. Confirm both prompts were readable on your unlock screen.'
sleep 3
echo 'Preview finished. No theme was selected and no boot images were rebuilt.'
PRIVATE_PREVIEW
