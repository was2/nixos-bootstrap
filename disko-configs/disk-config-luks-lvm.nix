{ lib, config, ... }:

let
  cfg = config.was2.diskLayouts;
in
{
  options = {
    was2.diskLayouts.lvm_on_luks.enable = lib.mkEnableOption "LVM on LUKS";
  };

  config = lib.mkIf cfg.lvm_on_luks.enable {
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
              "luks_${config.networking.hostName}" = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "pv_${config.networking.hostName}";
                  passwordFile = "/tmp/key.txt";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = [ "fido2-device=auto" "token-timeout=30" ];
                  };
                  content = {
                    type = "lvm_pv";
                    vg = "vg_${config.networking.hostName}";
                  };
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
              size = "8G";
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
