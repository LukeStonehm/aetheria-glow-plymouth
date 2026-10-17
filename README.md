# Aetheria Glow Plymouth

A Plymouth boot splash using the Aetheria artwork, with a soft glow that slowly pulses around the edges of the screen. It also styles the disk-unlock password prompt.

![Aetheria background artwork](background.png)

*Static preview. The glow animation and password prompt only show up in Plymouth.*

The artwork comes from [Aetheria by Dizziee](https://github.com/JJDizz1L/aetheria). This repo is only the boot splash, not the full Omarchy desktop theme.

## Requirements

Written for and tested on **EndeavourOS with dracut, systemd-boot, and LUKS disk encryption**. Other Arch-based setups should work, but the rebuild and recovery commands below may differ.

Disk encryption is optional. Without it you still get the artwork and glow during boot, just no password prompt. On a fast machine the splash may only show for a second or two, so the preview below is the best way to see it.

You need:

| Package | Why |
| --- | --- |
| `plymouth` | The splash itself. The Arch package includes the `script` plugin and the `label-pango` text plugin this theme uses. |
| `dracut` and `kernel-install-for-dracut` | Builds the boot image with the theme inside. EndeavourOS installs these by default on dracut systems. |
| A Sans and a Monospace font, e.g. `noto-fonts` | Used for the prompt text. Any fonts that `fc-match Sans` and `fc-match Monospace` resolve to will do. |
| `util-linux`, `coreutils`, `procps-ng` | Only for the preview script. Already present on a normal install. |

Plymouth should already be working on your system before you add this theme: `splash` must be on your kernel command line (on EndeavourOS, that's `/etc/kernel/cmdline`).

```sh
sudo pacman -S --needed plymouth noto-fonts
grep -w splash /etc/kernel/cmdline
```

If the `grep` prints nothing, sort out a basic Plymouth setup first. The [Arch wiki page](https://wiki.archlinux.org/title/Plymouth) covers it.

## Download

```sh
git clone https://github.com/LukeStonehm/aetheria-glow-plymouth.git
cd aetheria-glow-plymouth
sha256sum -c MANIFEST.sha256
```

## Try it before installing

`test-preview.sh` runs the theme from this folder in a throwaway Plymouth session. It shows a fake password prompt so you can check the text is readable on your screen. It doesn't install anything, change boot settings, or touch your disk encryption.

1. Save your work, press **Ctrl+Alt+F3**, and log in.
2. `cd` into this folder and run:

   ```sh
   sudo bash ./test-preview.sh
   ```

3. Type `PREVIEW` to start. Use made-up input only, **never your real passphrase**. The first password you type gets rejected on purpose, and the second is accepted.

If it hangs, switch to another console (**Ctrl+Alt+F4**) and run `sudo plymouth quit`. [TESTING.md](TESTING.md) has the full walkthrough and what to look for.

## Install

Installing means rebuilding your boot image. If something goes wrong, the unlock screen is the thing that breaks, so **make a backup boot entry first**.

### 1. Back up your current boot entry

Find the entry you currently boot:

```sh
sudo bootctl list --no-pager
```

Note the `linux` and `initrd` paths, and the `id` of the entry marked `(selected)`. Then copy them somewhere the rebuild won't touch, and add a boot entry for the copy. Replace the three values at the top with yours:

```sh
sudo bash <<'EOF'
set -euo pipefail
src_dir=/efi/YOUR-MACHINE-ID/YOUR-KERNEL-VERSION  # folder containing linux and initrd
entry=/efi/loader/entries/YOUR-ENTRY-ID.conf      # the selected entry's file
dst=/efi/aetheria-recovery

[[ ! -e $dst ]] || { echo "$dst already exists"; exit 1; }
mkdir "$dst"
cp "$src_dir/linux" "$src_dir/initrd" "$dst/"
sed -e 's/^title .*/title Pre-Aetheria recovery/' \
    -e "s|^linux .*|linux /aetheria-recovery/linux|" \
    -e "s|^initrd .*|initrd /aetheria-recovery/initrd|" \
    "$entry" > /efi/loader/entries/aetheria-recovery.conf
EOF
```

If your ESP is mounted at `/boot` instead of `/efi`, adjust the paths. If your entry has more than one `initrd` line (e.g. separate microcode), copy each file and keep each line rather than using the `sed` above.

Boot it once to make sure it works:

```sh
sudo bootctl set-oneshot aetheria-recovery.conf
sudo reboot
```

Don't continue unless that boots and unlocks normally.

### 2. Install the theme

```sh
plymouth-set-default-theme > previous-theme.txt

sudo install -d /usr/share/plymouth/themes/aetheria-glow
sudo install -m 644 aetheria-glow.plymouth aetheria-glow.script \
    background.png inner-glow.png panel.png \
    /usr/share/plymouth/themes/aetheria-glow/
sudo plymouth-set-default-theme aetheria-glow
```

### 3. Rebuild the boot image

```sh
sudo reinstall-kernels
```

Stop if it prints errors. Don't run mkinitcpio or GRUB commands on a dracut system.

### 4. Reboot

You should see the artwork, then the password prompt. Check your keyboard layout works when you type your passphrase.

## If something goes wrong

- **Press Esc** at the boot screen to switch to Plymouth's plain-text view.
- **Boot the backup.** Hold Space during startup to show the systemd-boot menu, then pick **Pre-Aetheria recovery**.
- **Switch back to your old theme** once you're booted:

  ```sh
  sudo plymouth-set-default-theme "$(cat previous-theme.txt)"
  sudo reinstall-kernels
  ```

The backup is a frozen copy. It won't get kernel updates, so delete it once you're happy:

```sh
sudo rm /efi/loader/entries/aetheria-recovery.conf
sudo rm -r /efi/aetheria-recovery
```

## Notes

- The artwork scales to fit any screen without stretching, with black bars where the aspect ratio doesn't match.
- Long prompts wrap instead of shrinking. Long passwords show a capped row of `*` followed by `...`, but Plymouth still receives everything you type.
- The theme never sees your passphrase. Plymouth only tells it how many characters you've typed.
- Multi-monitor setups and unusual GPUs aren't tested much. If a monitor stays blank, that's usually because the graphics driver hasn't brought it up yet, which the theme can't fix.

## Contributing

There's no build step. Before opening a PR:

```sh
bash -n test-preview.sh
sha256sum -c MANIFEST.sha256
```

Update the checksum for any file you change. To actually see your change, run the preview, not a full reinstall. [VALIDATION.md](VALIDATION.md) has notes on what has and hasn't been tested.

When reporting a bug, include your Plymouth version, your monitor setup, and whether it happened in the preview or at real boot. Never include passphrases or initramfs dumps.

## License

MIT. See [LICENSE](LICENSE). The Aetheria artwork is by Dizziee, from [JJDizz1L/aetheria](https://github.com/JJDizz1L/aetheria) (also MIT). The image files are unchanged from the originals.
