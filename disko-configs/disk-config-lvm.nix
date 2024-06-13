{ lib, config, ... }:

let
  cfg = config.was2.diskLayouts;
in
{
  options = {
    was2.diskLayouts.lvm.enable = lib.mkEnableOption "LVM";
  };

  config = lib.mkIf cfg.lvm.enable {
    disko.devices = {
      disk = {
        system = {
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              "${config.networking.hostName}-ESP" = {
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              "pv_${config.networking.hostName}" = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "vg_${config.networking.hostName}";
                };
              };
            };
          };
        }; 
      };
      lvm_vg = {
        "vg_${config.networking.hostName}" = {
          type = "lvm_vg";
          lvs = {
            swap = {
              size = "1G";
              content = {
                type = "swap";
              };
            };
            root = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            };
          };
        };
      };
    };
  };
}
