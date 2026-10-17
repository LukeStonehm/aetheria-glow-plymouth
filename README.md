# Aetheria Glow Plymouth

A custom Plymouth script theme for an existing Plymouth installation. The original 1920×1080 artwork and glow assets are unchanged. A translucent overlay breathes around the rectangular image perimeter; the artwork itself is static. The image fits the display without distortion, with black letterboxing where needed.

Artwork from [Aetheria by Dizziee (JJDizz1L)](https://github.com/JJDizz1L/aetheria), adapted here as a standalone Plymouth theme. This is not the full Omarchy desktop theme and does not require installing Omarchy.

![Aetheria background artwork](background.png)

*Static artwork preview only; the animated glow and password UI require Plymouth.*

**Status:** revision 2. Script-level validation is documented in [VALIDATION.md](VALIDATION.md); full Plymouth rendering, GPU/display behavior, and encrypted boot still need local testing. The installation instructions target an existing EndeavourOS + dracut + systemd-boot setup, not a fresh Plymouth installation.

**Start with [TESTING.md](TESTING.md).** It explains how to preview the theme and its password dialog from the extracted directory, before installing or selecting it. The preview uses invented input, never opens a LUKS device, and does not rebuild boot images.

## Get the theme

Clone the repository (or download and extract its ZIP):

```sh
git clone https://github.com/LukeStonehm/aetheria-glow-plymouth.git
cd aetheria-glow-plymouth
sha256sum -c MANIFEST.sha256
```

The checksum check detects changes to the listed files; it is not a signature or a runtime test. Read the preview helper and TESTING.md before running anything with `sudo`.

## What changed

- Active password, question, and message text is redrawn when the display size or origin changes.
- Explicit Sans and Monospace fonts, with main text at 16–24 points and an Escape hint at 14 points. Long text wraps instead of being scaled to tiny images.
- Password masks adapt to the available width; long input is represented by a capped mask with an ellipsis. Plymouth retains the entire submitted input.
- Prompt and message panels use their actual text heights and avoid overlap on supported display sizes.
- Zero-sized displays during discovery do not cause zero-sized image scaling.
- A temporary preview helper tests the actual Plymouth password UI with a simulated rejection/retry and a separate unmasked question.
- dracut-specific recovery instructions and clearer boot-backup guidance.

## Files

- `aetheria-glow.plymouth`: script-plugin descriptor with the installation paths below.
- `aetheria-glow.script`: production theme; no custom keyboard-input callback.
- `background.png`, `inner-glow.png`, `panel.png`: the only image assets used at boot.
- `original.jpg`: reference artwork, not loaded at boot.
- `test-preview.sh`: optional, explicitly invoked local-VT preview; not installed into the boot theme.
- `TESTING.md`, `VALIDATION.md`, and this README.

## Install after the preview passes

These instructions assume EndeavourOS already boots correctly with dracut, systemd-boot, LUKS2, and a working Plymouth setup. Do not change encryption parameters, crypttab, keyfiles, or initramfs generator to add this theme. Plymouth operates before SDDM/Plasma; KDE Wayland and the Plasma lock-screen wallpaper are separate.

1. Read TESTING.md and pass the dummy preview on the screen and keyboard you use for unlocking.
2. Keep recovery media available. Preserve a tested, independent working kernel/initramfs pair (or UKI) and a boot entry pointing to it **before** running a kernel reinstall. An ordinary fallback regenerated with the same new theme is not an independent backup. Exact backup paths depend on whether your installation uses separate kernel/initrd files or UKIs. Check `bootctl list` and your existing recovery workflow; do not guess or edit LUKS settings.
3. From the directory containing this README, record the current theme:

   ```sh
   plymouth-set-default-theme | tee previous-theme.txt
   ```

4. Check whether `/usr/share/plymouth/themes/aetheria-glow` already exists. If it does, stop and preserve that directory before replacing it. The following block deliberately refuses an existing destination. It copies only the production files and selects the theme; it does not rebuild any boot image:

   ```sh
   (
     set -eu
     target=/usr/share/plymouth/themes/aetheria-glow
     if sudo test -e "$target" || sudo test -L "$target"; then
       echo "Destination exists: preserve it before replacing it." >&2
       exit 1
     fi
     sudo install -d -m 755 "$target"
     sudo install -m 644 aetheria-glow.plymouth aetheria-glow.script \
       background.png inner-glow.png panel.png "$target/"
     sudo plymouth-set-default-theme aetheria-glow
   )
   ```

5. Confirm your established kernel command line includes `splash`; `quiet` is optional. For the normal EndeavourOS systemd-boot/kernel-install workflow, persistent kernel arguments are managed through `/etc/kernel/cmdline`. Preserve all existing root, LUKS, resume, and other parameters. If your setup is customized, use its established method.
6. After preserving recovery and checking the selected theme, rebuild using the established EndeavourOS systemd-boot/dracut command:

   ```sh
   sudo reinstall-kernels
   ```

   Read the output and stop on errors. Do not also run mkinitcpio or GRUB commands. This step can regenerate multiple boot images and entries. The selected theme has to be included in the image that your entry actually loads.
7. If you inspect the generated image with `lsinitrd`, use its actual path from your boot configuration. Check for the Plymouth module, script and label/font support, and the selected theme's descriptor, script, and PNGs. Existing crypt/keyboard integration must still be present. Do not publish a complete initramfs listing or extracted contents: your existing configuration may include sensitive files or keys.
8. Perform the real-boot checklist in TESTING.md. A dummy preview cannot establish that dracut starts its password agent early enough or that the initramfs has the correct keyboard, fonts, and GPU support.

## Recovery and rollback

If graphics are wrong during boot, press **Esc** to show Plymouth's text/details view. If input or the UI remains unusable, use the separately preserved working entry.

On an editable systemd-boot entry, show the menu (typically hold Space during startup), select the entry, and press `e`. For a one-boot dracut test, append `plymouth.enable=0`; `rd.plymouth=0` specifically disables Plymouth in the initramfs. Keep all existing encryption/root arguments. Editing may be disabled by bootloader configuration or unavailable for a particular signed UKI workflow; use your working recovery entry or live media in that case.

After booting successfully, select the previous theme recorded in `previous-theme.txt` with `sudo plymouth-set-default-theme PREVIOUS_THEME`, substituting its actual name, then run `sudo reinstall-kernels` again. If the previous theme was an older `aetheria-glow`, restore its preserved directory first. Do not remove a selected theme directory before choosing another working theme and rebuilding.

The mkinitcpio parameter `disablehooks=plymouth` is intentionally absent from the dracut recovery procedure.

## Appearance, performance, and limitations

The animation requests 50 refreshes per second and advances phase by 2π/200 per refresh. The nominal period is four seconds; fewer delivered refreshes stretch it. Opacity is `0.18 + 0.72 * (1 - Math.Cos(phase)) / 2`. With the overlay's maximum alpha of 84/255, peak edge coverage ranges from about 6% to 30%. This is one overlay, not a video/frame sequence. Full-screen redraws still have a cost, especially at 4K; no hardware performance claim is made.

The theme uses Plymouth's shared display coordinate space and common safe dimensions, as the upstream script example does. It redraws when that area's size or origin changes. It cannot enable a monitor that Plymouth/KMS has not initialized. Test docked and undocked configurations separately. Displays smaller than 640×480, unusual display arrangements, font fallback differences, and GPU handoff still require local checking. No claim of universal per-output handling is made.

Prompts wrap to at most four lines (two below 600 pixels high); messages use two lines (one below 600 pixels). Text omitted for space has `...`; an individual unbroken word/identifier wider than a line becomes `[...]`. The Escape/details view remains available to read the full original prompt. The latest informational message is shown; this is not a message-history viewer.

The password callback receives a prompt and a masked-character count, not the passphrase. The separate question callback intentionally displays the question response openly. There is no custom input capture, network access, or LUKS manipulation in the theme. Correct font/label support must exist both on the running system and inside the boot image.

## Development and validation

There is no build step or checked-in automated interpreter test harness. From the repository root, run:

```sh
bash -n test-preview.sh
sha256sum -c MANIFEST.sha256
```

These check shell syntax and file integrity only. For runtime validation, use the dummy local-VT preview in TESTING.md; do not select the theme or rebuild boot images just to test a change. Update the affected checksum entries when intentionally changing listed files.

See VALIDATION.md for historical script-level tests and remaining hardware-dependent checks. When reporting an issue, include your Plymouth version, display arrangement, and whether it occurred in the dummy preview or during real boot. Never include passphrases, keyfiles, or complete initramfs dumps.

## License and attribution

Licensed under the [MIT License](LICENSE). The original Aetheria artwork comes from [JJDizz1L/aetheria](https://github.com/JJDizz1L/aetheria), published under MIT with copyright © 2025 Dizziee; that notice is retained in LICENSE alongside this project's notice. All four included image assets remain byte-for-byte unchanged from the original package used for this revision.

## References

- [Plymouth scripting reference](https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/)
- [Upstream source mirror: script example and interpreter](https://github.com/freedesktop-unofficial-mirror/plymouth/tree/master/src/plugins/splash/script)
- [Plymouth client manual](https://man.archlinux.org/man/plymouth.1.en)
- [Arch Plymouth integration](https://wiki.archlinux.org/title/Plymouth)
- [EndeavourOS dracut/rebuild instructions](https://discovery.endeavouros.com/dracut/)
- [dracut kernel command-line manual](https://man7.org/linux/man-pages/man7/dracut.cmdline.7.html)
