# Revision 2 validation

The original archive was read without modification. Original ZIP SHA-256:

`dc28273adb2ea16b909462028b6352643624d1fce0eb6c5cc38ea62ea781c2c2`

All four images (`background.png`, `inner-glow.png`, `panel.png`, `original.jpg`) and the `.plymouth` descriptor were preserved byte-for-byte. The background PNG matches the included JPEG's decoded RGB pixels; the glow's centre is transparent and maximum alpha is 84/255.

The revised production `.script` was parsed and executed with the upstream Plymouth script interpreter from the freedesktop source mirror, using the real upstream Math and String libraries. Display, sprite, image, and callback plumbing were simulated; text sizes were measured with Pango, and a composed preview was inspected visually. This is stronger than a separate reimplementation of the theme's logic, but is not a full Plymouth daemon/renderer test.

Scenarios covered 640×480, 800×600, 1280×720, 1920×1080, 2560×1440, 3840×2160, and portrait 1024×1280; nonzero display origins; messages during password entry; long/wrapped prompts; UTF-8 preservation; masking and overflow; question entry; normal-mode cleanup; temporary zero-sized display discovery; and the complete 200-refresh glow cycle. All assertions passed in the final run. The preview helper's shell syntax was also checked with `bash -n`, and its non-root refusal was exercised.

The helper was reviewed for temporary mounts, daemon ownership checks, dummy-input disposal, bounded waits, and cleanup. It was NOT launched with root privileges or allowed to take over a real VT in this build session. No host Plymouth installation, theme selection, kernel argument change, bootloader change, initramfs rebuild, or disk unlock was performed. There was no full daemon, real encrypted boot, or hardware multi-monitor/GPU test.

Use TESTING.md on your own local console before installation. Font metrics/fallback, Plymouth package versions, KMS/SimpleDRM, active displays, keyboard layout, and initramfs content must still be validated locally. The font names use system fallback; required fonts and a label plugin must be included in the boot image by the existing Plymouth/dracut setup.
