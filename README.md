# Xiaomi Redmi Note 9S → postmarketOS (Phosh)

Pre-built **postmarketOS v25.12 + Phosh** flash bundle for the **Xiaomi Redmi Note 9S** (pmaports codename `xiaomi-miatoll`, SKU `curtana`). Likely also works on the **Redmi Note 9 Pro** (`joyeuse`) and **Note 9 Pro Max** (`excalibur`) — same miatoll family, untested by me. **~10 minutes to lockscreen.** Ships with the Plymouth workaround you'll otherwise hit at the pmOS logo + "Loading…" forever.

| Lockscreen | App drawer | Console + fastfetch |
|:---:|:---:|:---:|
| ![Lockscreen](screenshots/lockscreen.jpg) | ![App drawer](screenshots/app-drawer.jpg) | ![Console](screenshots/console-fastfetch.jpg) |

## Download

Binary images live in **[GitHub Releases](../../releases/latest)** (too big for git). You need four files from the latest release:

| File | Size | Compressed | Goes to |
|---|---|---|---|
| `xiaomi-miatoll-boot.img` | 256 MiB | `.img.zst` ~50 MB | `cache` *(kernel partition on miatoll)* |
| `xiaomi-miatoll-root.img` | 2.5 GiB | `.img.zst` ~800 MB | `userdata` |
| `u-boot-sm7125.img` | 1008 KiB | not compressed | `boot` *(mainline U-Boot for SM7125)* |
| `SHA256SUMS` | — | — | integrity check |

```sh
# pick a folder, download, decompress, verify
gh release download --repo asidko/redmi-note-9s-postmarketos --pattern '*.img*' --pattern 'SHA256SUMS'
# or grab manually from the Releases page
zstd -d *.zst
sha256sum -c SHA256SUMS         # all 3 must say OK
```

## ⚠️ Read first

- **Destructive.** Wipes `cache`, `userdata`, `boot`. Modem, persist, keymaster, devcfg, `super` survive — radio works, revert to MIUI possible.
- **Tested on Redmi Note 9S** (`curtana`). The same images may work on `joyeuse` / `excalibur` (Note 9 Pro / Pro Max — miatoll family) but are untested there.
- **Never flash `*-boot.img` to `boot`** — on miatoll, `cache` = kernel, `boot` = U-Boot. Swap = brick.
- Battery ≥ 30 %. No power-cycle mid-flash.

## Prerequisites

**Laptop:** Linux + `fastboot` (`apt install android-tools-fastboot android-sdk-platform-tools-common`, or your distro's equivalent) + `zstd`. USB data cable. Run fastboot with `sudo` if udev rules aren't installed.

**Phone — bootloader must be unlocked.** Three steps, 5–7 days total:

0. **Sign in to <https://account.xiaomi.com/>** — confirm the Mi account is active, signed in on the phone, with a verified email (Xiaomi rejects unlock requests without one).
1. **Submit the unlock request** (cross-platform): <https://github.com/offici5l/MiUnlockTool>
2. **Wait 5–7 days** (Xiaomi-account-age gated, no skip).
3. **Do the unlock** (Windows-only, official): <https://en.miui.com/unlock/download_en.html>

Verify: `fastboot oem device-info` shows `Device unlocked: true`.

## Flash

```sh
cd /path/to/extracted-folder
sha256sum -c SHA256SUMS                                # all 3 must say OK
```

Power phone off → hold **Volume DOWN + Power** to fastboot → plug USB.

```sh
fastboot devices                                       # one line expected
fastboot getvar product                                # must say: product: curtana
```

Stop if `product` is anything other than `curtana` (`joyeuse` / `excalibur` are Note 9 Pro / Pro Max — likely OK but untested).

```sh
fastboot flash cache    xiaomi-miatoll-boot.img        # ~10 s
fastboot flash userdata xiaomi-miatoll-root.img        # ~60–120 s, 3 sparse chunks
fastboot erase dtbo                                    # mainline ignores it
fastboot flash boot     u-boot-sm7125.img              # ~1 s
fastboot reboot
```

USB drops — that's normal. On the phone you'll see U-Boot text (~5 s) → pmOS logo → **scrolling boot logs** (intentional, see build notes) → Phosh lockscreen in **1–5 min** on first boot.

## Login

| | |
|---|---|
| User | `user` |
| Password | `1234`  (also sudo) |
| Hostname | `redmi` |

SSH is enabled by default. On the phone connect Wi-Fi, find the IP via Terminal: `hostname -I`. Then from your PC:

```sh
ssh user@<phone-ip>       # password: 1234
ssh user@redmi.local      # mDNS — macOS and most Linux work out of the box
```

**🔒 Change the password immediately** — `passwd` over SSH, or Settings → Users in Phosh. `1234` is unsafe.

## Hardware support

`xiaomi-miatoll` is **testing** tier in pmaports. Works: Wi-Fi, cellular voice + data, audio, GPU, sensors. Broken/missing: camera, fingerprint, NFC, HW video decode. Wiki: <https://wiki.postmarketos.org/wiki/Xiaomi_Redmi_Note_9S_(xiaomi-miatoll)>.

## Troubleshooting

- **`fastboot devices` empty / "no permissions":** bad/charge-only cable, missing udev, or run with `sudo`.
- **"Volume Full" on flash:** image corrupted — re-run `sha256sum -c` and re-download.
- **Black screen > 7 min:** hold Power 10 s. If dead, Vol-Down + Power → restart from the verify step. **Vol-Up + Power is MIUI recovery, NOT EDL** on this device.
- **Stuck on pmOS logo + "Loading…":** you're on a build without the Plymouth fix. This bundle has it baked in — re-flash `cache` from this release.
- **No Wi-Fi:** `firmware-xiaomi-miatoll` is included; reboot once. Check `dmesg | grep firmware` over SSH.

## Build notes (for rebuilders)

`pmbootstrap` v3.10.1, `pmaports` `v25.12`, channel `systemd-v25.12`, Alpine aarch64 cross-build. Two non-default changes are required:

1. **Smaller `boot_size`** — miatoll's `cache` is only ~384 MiB, but pmbootstrap defaults to 512 MiB and refuses smaller. Patch `sanity_check_boot_size()` in `pmb/install/_install.py` to allow `< 512` with a warning, then `pmbootstrap config boot_size 256`.
2. **Plymouth disabled in kernel cmdline** — mainline Plymouth hangs on miatoll's DRM driver (boot stalls at the pmOS logo forever). Mount the generated `xiaomi-miatoll-boot.img` and edit `/loader/entries/pmos.conf`: replace `quiet loglevel=2` with `plymouth.enable=0 console=tty0 systemd.show_status=true` (verbose flags are optional but useful — this bundle keeps `loglevel=7` and the systemd info logging so on-screen debugging is possible).
