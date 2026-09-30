# filesystems.nix
#
# Mounts, swap and storage maintenance. Devices are addressed by filesystem
# UUID; the comments name the physical drive, since the kernel's sdX names
# shift between boots.
{ ... }: {
    # [nvme0n1p2] Samsung 970 EVO Plus 500 GB.
    fileSystems."/" = {
        device = "/dev/disk/by-uuid/f3e63afc-6602-4f46-845d-bd6d5bc6afe3";
        fsType = "ext4";
    };

    # [nvme1n1p1] Samsung 970 EVO Plus 1 TB.
    fileSystems."/home" = {
        device = "/dev/disk/by-uuid/4d656a69-dc46-46b6-bec3-934e12415711";
        fsType = "btrfs";
        options = [ "compress=zstd:1" "noatime" ];
    };

    # Seagate ST4000DM004 4 TB, partition 2 (partition 1 is ~/Repository).
    fileSystems."/home/me/Mega" = {
        device = "/dev/disk/by-uuid/ccee2c99-427f-40f1-ad72-af6c81be4379";
        fsType = "ext4";
    };

    # WD Black WD4005FZBX 4 TB.
    fileSystems."/home/me/Music" = {
        device = "/dev/disk/by-uuid/bf9410ed-bf55-4341-97f5-5576f80ce071";
        fsType = "ext4";
    };

    # Seagate ST4000DM004 4 TB, partition 1.
    fileSystems."/home/me/Repository" = {
        device = "/dev/disk/by-uuid/2cf8ca9d-43ab-4ef5-99ff-0a909e765c5e";
        fsType = "btrfs";
        options = [ "compress=zstd:1" "noatime" ];
    };

    # WD Black WD4005FZBX 4 TB.
    fileSystems."/home/me/Videos/Movies" = {
        device = "/dev/disk/by-uuid/52dfd9d6-7557-45fd-83c6-a6bfff2c0c83";
        fsType = "ext4";
    };

    # WD Red Plus WD80EFPX 8 TB (whole disk, no partition table).
    fileSystems."/home/me/Videos/Television" = {
        device = "/dev/disk/by-uuid/a7007b9d-f315-4dec-83cd-ef883729e3c0";
        fsType = "ext4";
    };

    # [nvme0n1p1] EFI system partition.
    fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/3430-092D";
        fsType = "vfat";
    };

    swapDevices = [{
        device = "/swapfile";
        size = 16 * 1024;  # 16GB
    }];

    zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 25;
        priority = 100;
    };

    services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [ "/home" "/home/me/Repository" ];
    };
}

# <> #
