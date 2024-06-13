{ lib, config, inputs, ... }:
with inputs;

let 
  cfg = config.was2;
in 
{
  options = {
    was2.installDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/pleaseSetNixOSOption-was2.installDevice";
    };
  };

  imports = [
    disko.nixosModules.disko
    ./disk-config-lvm.nix 
    ./disk-config-luks-lvm.nix
    ];

  config = {
    disko.devices.disk.system.device = cfg.installDevice;
  };
}