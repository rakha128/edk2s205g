# Samsung Galaxy S20 5G (x1q / SC-51A) — SM8250 UEFI port

Status: **scaffolded, never booted.** This is a UEFI firmware port only. It is
not a Windows port and there is no ACPI/DSDT for x1q.

## Files added

| File | Purpose |
| --- | --- |
| `configs/devices/x1q.conf` | build.sh device config (SoC, vendor, boot image header) |
| `Platform/Samsung/sm8250/x1q.dsc` | device DSC (panel, framebuffer, DPI, product strings) |
| `Platform/Samsung/sm8250/x1q.fdf.inc` | per-device DXE drivers + ACPI tables |
| `Platform/Samsung/sm8250/Library/x1q/PlatformMemoryMapLib/` | UEFI memory map |
| `Platform/Samsung/sm8250/FdtBlob_compat/x1q.dtb` | device tree appended to the boot image |
| `.github/workflows/main.yml` | added `x1q` to the build matrix |

## What is verified, what is a guess

Verified from an actual x1q `boot.img` (dtb extracted from it):

* framebuffer / continuous splash is at **0x9C000000**, region size `0x2300000`
  (`reserved-memory/cont_splash_region@9c000000` in the dtb). This matches the
  `Display Reserved` entry copied from r8q (`0x9C000000`, size `0x02400000`,
  which also covers `dfps_data_region@9E300000`).
* the panel is driven at **1440x3200** (native mode, like every other Samsung
  target in this tree; the 36 MiB splash carveout is consistent with that at
  4 bytes per pixel).
* SoC id: `qcom,msm-id = <0x164 0x20001>` (kona v2.1 / SM8250).

The dtb was extracted from a real x1q boot image (`AIK_x1q/split_img/boot.img-dtb`
in the GoRhanHee/kernel_samsung_sm8250 repo, sha256
`6c82085b6016efc51512a5af42d1022e97f51d49c573a92b00993add72673395`). It is the
generic kona base dtb; x1q-specific nodes (panel, touch, regulators) live in the
`dtbo` overlays and are not needed to boot UEFI.

Guesses / not yet verified on hardware:

* `PlatformMemoryMapLib` is copied from r8q and deliberately stops at **6 GiB**
  of RAM even though the phone has 12 GiB. Mapping the upper 6 GiB before
  knowing Samsung's high reserved regions could corrupt firmware. Extend the
  last `RAM Partition` entry only after reading the real map from the device.
* `ButtonsDxe` is the **generic SM8250** binary; x1q has no per-device binary in
  `Platform/EFI_Binaries`. If volume keys do not work, try
  `Drivers/Devices/r8q/ButtonsDxe/ButtonsDxe.efi`.
* No x1q DSDT exists, so the ACPI table blob is the same common-table set r8q
  uses. That is fine for UEFI/Linux, useless for Windows.
* Boot image header version 1, same as r8q. The stock x1q image uses header v2;
  if the bootloader refuses the generated image, that is the first thing to
  change (`BOOTIMG_HEADER_VERSION` in `configs/devices/x1q.conf`).

## Build

You need a Linux x86_64 machine (macOS cannot build this: the build needs
`aarch64-linux-gnu-`, `iasl`, GNU getopt, etc.), or GitHub Actions.

Local Linux:

```sh
git clone --recursive https://github.com/<your-fork>/edk2-msm.git
cd edk2-msm
./build.sh --device x1q
# output: boot-x1q.img
```

GitHub Actions: fork the repo, push these changes to `master`, and download the
`x1q` artifact from the workflow run. `build.sh` initializes the submodules
itself, so a plain `actions/checkout` is enough.

## Flash (read this before touching the phone)

Samsung does not use fastboot for this. The usual flow:

1. Unlock the bootloader (OEM unlocking in developer options, then the
   download-mode unlock). Confirm KG state is not permanently locked.
2. Put `boot-x1q.img` into a tar: `tar -cf boot-x1q.tar boot-x1q.img`.
3. Reboot to download mode (power off, hold Vol Down + Vol Up, plug USB), flash
   the tar in Odin's **AP** slot. On macOS use Jodin3/WebUSB or a Windows VM;
   Heimdall support for SM8250 Samsung devices is unreliable.
4. If the bootloader refuses to boot the unsigned image, flash a `vbmeta.img`
   with AVB verification disabled (`fastboot --disable-verity
   --disable-verification flash vbmeta vbmeta.img` on a device that exposes
   fastboot, or the equivalent Odin tar), then flash boot again.

Recovery: download the stock SC-51A firmware for your region/CSC and flash
AP + BL + CP + CSC (or HOME_CSC to keep data) in Odin. Do not skip this — have
the stock firmware on hand before the first flash.

## First boot

Expected if everything works: display lights up with the UEFI/SimpleInit UI
after a few seconds (SimpleInit auto-boots after its timeout).

If the screen stays black:

1. Re-check the resolutions: try 1080x2400 in `x1q.dsc` (some Samsung
   bootloaders leave the splash at FHD+ even on a QHD+ panel).
2. Check the framebuffer address is still `0x9C000000` on your firmware build.
3. Build a DEBUG image with UART (`./build.sh --device x1q --uart`); SM8250
   debug UART is exposed on the USB-C SBU pins and needs a special cable.
4. If it reboots or hangs before display init, the memory map or FD base
   (`0xCE000000` from `configs/sm8250.conf`) conflicts with something Samsung
   reserved.

## What would make this a real port

* The real `/proc/iomem` from a rooted stock device (or UEFI `memmap`) to fix
  the 12 GiB memory map.
* The x1q `dtbo.img` (the base dtb above is generic; panel/touch/regulators
  live in the dtbo overlays) if you want Linux to boot further.
* A UART log from the first boot. Everything else is guesswork without it.
