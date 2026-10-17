# Repository guidance

## Runtime and editing
- This is a standalone Plymouth script-plugin theme, not a JavaScript app. There is no build/package manager, CI, or checked-in automated interpreter harness.
- `aetheria-glow.plymouth` hardcodes `/usr/share/plymouth/themes/aetheria-glow` for both images and script. The preview exposes the working copy at that path through private bind mounts; running the script directly is not a preview.
- Only the descriptor, `.script`, `background.png`, `inner-glow.png`, and `panel.png` are installed. `original.jpg` is reference artwork; the preview helper is not a boot-time component.
- Preserve the original image assets unless explicitly asked to change them; their byte-for-byte preservation is documented in `VALIDATION.md`.
- The script uses Plymouth's interpreter (`fun`, `local.*`, `global.*`), not JS syntax. Keep the literal tab delimiter in `wrap_text`: this interpreter does not support a `\t` escape.
- Plymouth owns password input and submission. Keep the password callback limited to prompt + masked count; do not add keyboard capture or retain/log passphrases. The separate question callback intentionally displays its response openly.
- Layout uses shared display dimensions AND origin, skips zero-sized displays, and redraws cached prompt/message state after geometry changes. Preserve these behaviors; this is not independent per-monitor rendering.

## Verification
- From the repository root: `bash -n test-preview.sh` checks shell syntax; `sha256sum -c MANIFEST.sha256` checks packaged-file integrity, not runtime correctness. Update affected manifest entries when intentionally changing listed files.
- `VALIDATION.md` records historical upstream-interpreter tests, but their harness is not included. Do not report those scenarios as newly run or treat shell syntax/integrity checks as a Plymouth runtime test.
- For a real dummy preview, follow `TESTING.md`: `sudo bash ./test-preview.sh` from a local `/dev/ttyN`, not SSH or a desktop terminal. It requires installed Plymouth with script and label/font support, refuses existing daemons, and requires typing `PREVIEW`.
- With sudo `use_pty`, `tty` reports `/dev/pts/N`; `SUDO_TTY` identifies the real preview VT. Keep confirmation on the controlling terminal, never redirect stdin to the physical VT: sudo also reads it and can swallow input/signals.
- Use invented input only. The preview rejects the first submission, accepts the second, then asks an unmasked question. Each request times out after 40 seconds; the whole preview after 120. A timeout is not a pass, and successful client commands do not prove the intended artwork loaded.
- Do not bypass mount-namespace isolation to run in a restricted environment. Real VT/GPU behavior and encrypted boot require local validation; report them as untested when unavailable.

## Boot-system boundaries
- Development/preview must not select a default theme, alter encryption/kernel/bootloader settings, or rebuild boot images. Installation is a separate, explicitly requested operation; use `README.md` and its recovery prerequisites.
- The documented target is EndeavourOS with dracut + systemd-boot + LUKS2. Its rebuild command is `sudo reinstall-kernels`, not mkinitcpio or GRUB commands. Preserve an independent tested boot image/entry before rebuilding; a fallback regenerated with the same theme is not an independent backup.
