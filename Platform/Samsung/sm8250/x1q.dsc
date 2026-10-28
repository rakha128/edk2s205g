[Defines]
  VENDOR_NAME                    = Samsung
  PLATFORM_NAME                  = x1q
  PLATFORM_GUID                  = 6c0b4dbd-132c-4565-8492-bee27bb22a1b
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010019
  OUTPUT_DIRECTORY               = Build/$(PLATFORM_NAME)
  SUPPORTED_ARCHITECTURES        = AARCH64
  BUILD_TARGETS                  = DEBUG|RELEASE
  SKUID_IDENTIFIER               = DEFAULT
  FLASH_DEFINITION               = Platform/Qualcomm/sm8250/sm8250.fdf
  DEVICE_DXE_FV_COMPONENTS       = Platform/Samsung/sm8250/x1q.fdf.inc

!include Platform/Qualcomm/sm8250/sm8250.dsc

[BuildOptions.common]
  # Not consumed by anything in the current tree; kept for parity with r8q and
  # in sync with the amount of RAM PlatformMemoryMapLib exposes today.
  GCC:*_*_AARCH64_CC_FLAGS = -DENABLE_SIMPLE_INIT -DRAM_SIZE=6

[PcdsFixedAtBuild.common]
  # Galaxy S20 5G (SC-51A) panel: 6.2" 1440x3200 Dynamic AMOLED, ~563 ppi.
  # 0x9C000000 is confirmed by the x1q boot.img device tree:
  #   reserved-memory/cont_splash_region@9c000000 = 0x9C000000 + 0x2300000
  # The resolution follows the panel's native mode, like every other Samsung
  # target in this tree (Fold 2152x1536, Z Fold 3 2208x1768, S10 Lite
  # 1080x2400, S23 1080x2340).
  # If the UEFI splash comes out tiled/skewed, the bootloader splash is FHD+
  # instead: try 1080x2400.
  gQcomTokenSpaceGuid.PcdMipiFrameBufferWidth|1440
  gQcomTokenSpaceGuid.PcdMipiFrameBufferHeight|3200
  gQcomTokenSpaceGuid.PcdMipiFrameBufferAddress|0x9C000000

  # Simple Init
  gSimpleInitTokenSpaceGuid.PcdGuiDefaultDPI|560

  gRenegadePkgTokenSpaceGuid.PcdDeviceVendor|"Samsung"
  gRenegadePkgTokenSpaceGuid.PcdDeviceProduct|"Galaxy S20 5G"
  gRenegadePkgTokenSpaceGuid.PcdDeviceCodeName|"x1q"
