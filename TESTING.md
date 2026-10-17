# Test the password prompt before installing

This is a **dummy Plymouth password-dialog test**, not a LUKS unlock. It exercises the theme and Plymouth's masked-input/submission/retry path without accessing an encrypted device. It cannot prove that dracut will start the prompt correctly during boot. Do not enter your real disk passphrase in the preview.

## What the helper changes temporarily

`test-preview.sh` creates a root-owned temporary directory and a private mount namespace. Inside that namespace only, it exposes the extracted theme at the paths expected by Plymouth. Other installed themes remain accessible for fallback. A fake command line selects Aetheria for this test daemon only.

It does not write `/etc/plymouth/plymouthd.conf`, select a default theme, change the real kernel command line, run dracut/kernel-install, edit systemd-boot, or call cryptsetup. Normal exit, signal, or timeout stops the test daemon and removes the temporary mounts/files. Mounts also disappear when the namespace exits. A forced kill or power loss can leave a root-owned `/tmp/aetheria-preview.*` directory, but does not persist a theme selection or boot change.

Root permission is needed to use the local VT and private bind mounts. Read the short helper before running it. Run only the copy you intend to trust; never run it during boot or against an existing Plymouth daemon.

## Before starting

1. Clone the repository or extract its ZIP. Do not copy the theme into `/usr/share` or select it yet.
2. You need the distro's `plymouth` package, its script plugin, and normal label/font support already available on the running system. The helper also uses standard util-linux/coreutils/procps tools. If a prerequisite is missing, it stops. Installing the Plymouth package is separate from installing this theme; do not rebuild boot images merely to run the preview.
3. Save your desktop work. A preview can temporarily disrupt the graphical display even though it leaves boot configuration untouched.
4. Switch to a local text VT, for example **Ctrl+Alt+F3**, and log in. Do not use a Plasma terminal, SSH, an active boot console, or a nested terminal. Verify that you can switch to another text VT for recovery. Your graphical session is often on F1 or F2; the actual VT may differ.
5. Have this extraction directory's absolute path available. The helper refuses an existing Plymouth daemon rather than stopping it. If it refuses, stop here and investigate; do not kill a daemon blindly.

## Run the preview

In the text VT, enter the extracted `aetheria-glow` directory, then run:

```sh
sudo bash ./test-preview.sh
```

Read its notice and type `PREVIEW` to start. This is the only helper to run for the pre-install test. No `plymouth-set-default-theme` command or boot rebuild is needed.

Confirmation expires after 30 seconds without starting a daemon. With sudo's pseudo-terminal mode, the helper may show `/dev/pts/N` as its input terminal; it uses `SUDO_TTY` to identify the actual `/dev/ttyN` preview console. Run the command exactly as above: do not redirect input from `/dev/tty3`, disable sudo's pseudo-terminal protection, or run from SSH/a desktop terminal to bypass the console check.

The sequence is:

1. Artwork and breathing border appear for about three seconds. Confirm it is the Aetheria artwork, not a fallback theme or just a text console. A client command succeeding does not prove the intended theme loaded.
2. A long dummy password prompt and a separate test message appear. Type invented input, try backspace, and confirm only `*` characters appear. A long mask is capped with `...`, without limiting what Plymouth accepts.
3. Press **Esc** to show details, verify that the dummy prompt is still usable, then press **Esc** to return. Test this before submitting so you know the fallback works.
4. Submit an invented value such as `dummy-test`. The checker deliberately rejects its first invocation, regardless of the value. A second prompt should appear. Submit another invented value; the checker accepts its second invocation. There is no real password to get right, and no LUKS device is opened.
5. A separate **unmasked** dummy question appears. Type a harmless word and Enter. Visible input here is expected; it is a different Plymouth interface from the masked password dialog.
6. A completion message appears, then the preview quits and restores the VT. Each input request has a 40-second timeout; the complete preview has a 120-second watchdog. Timeout is a stopped/incomplete test, not a pass.

All submitted data is discarded; the helper does not print it or put it in a command argument. The retry checker stores only empty markers indicating its first and second invocations, never the submitted value. No debug logging is enabled. Still use dummy input only.

## If the preview gets stuck

Switch to the other text VT and run:

```sh
sudo plymouth quit
```

This is appropriate for the daemon you just launched for the preview; the helper refused to start if it detected another one. If necessary, wait for its watchdog. Do not run a kernel rebuild or change encryption settings to fix a preview. If the VT's text state is unusual after it stops, `reset` on that VT can restore its terminal presentation. A GPU/VT problem can exceed what shell cleanup can repair; saved desktop work and the second VT remain important.

If namespace creation or mounts are forbidden by your environment, the helper stops. Do not remove the isolation to make it run; use a normal local EndeavourOS console or an isolated test VM instead.

## Pass criteria

- Correct artwork, aspect ratio, and visible smooth pulse.
- Prompt, mask, hint, and message are legible and inside the screen.
- Backspace changes the mask; the mask does not reveal the invented input.
- First submission is rejected, second accepted, and the prompt resets appropriately.
- Escape/details and return to graphics work.
- Unmasked question works, and the preview exits cleanly.

Run the test again in the display arrangements you actually use, especially a docked laptop or external unlock screen. A monitor not initialized by Plymouth cannot be fixed by theme layout. The helper does not force mode changes or hotplug displays; those transitions remain hardware-dependent. If the correct theme or text never appears, do not install it yet.

## After the dummy test: real encrypted-boot validation

Only a boot using the candidate initramfs/UKI can validate the whole LUKS2 + dracut + keyboard + GPU path. An ordinary userspace preview cannot do that. Before selecting/rebuilding as described in README.md, preserve an independent, tested working boot image/entry and have recovery media available. If you want a real boot test before replacing your normal image, prepare a separate candidate image and one-shot test entry using your established boot workflow; this package does not generate one or guess your disk/ESP/UKI paths.

On the candidate boot, check the normal unlock display, type your real passphrase **only into the real boot unlock prompt**, and confirm that the disk unlocks and boot reaches SDDM. If deliberately testing a wrong entry and retry, consider any existing retry limits or hardware-token policy first; the dummy test already exercises a simulated rejection without those effects. Check the keyboard layout, not just the number of stars: it is determined by the initramfs configuration, not by Plasma.

Confirm the prompt disappears after success, and that Escape/details remains useful. If the UI is unusable, stop using the candidate, boot the independently preserved working entry, and follow the dracut rollback instructions in README.md. Keep that recovery entry until both encrypted boot and your normal display arrangement have been tested successfully.
