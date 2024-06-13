{ lib, pkgs, config, inputs, ... }:

{
  imports = with inputs; [
    ./disko-configs
    agenix.nixosModules.default
  ];

  # Use the systemd-boot EFI boot loader and initrd
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ensure luks fido2 can work
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.systemd.enable = true;

  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;

  # Users / Groups config #######################################################
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOydfhxPGVM4CNDD2r9rG2hwoOgfzz0AArSWw+jbreSuAAAAIHNzaDp3YXMyLXByaW1hcnkteXViaWtleS1ub3RvdWNo ssh:was2-primary-yubikey-notouch"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMyCcp/ezq5aPGqeeQK17aJOikDkBo/+R4Wgv/BlzndIAAAAGHNzaDp3YXMyLXByaW1hcnkteXViaWtleQ== ssh:was2-primary-yubikey"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILfEJ+lwOpxRMH+7u4TnLl7opRcclz8QosUzCcNDbPhuAAAAEnNzaDp5dWJpa2V5LWJhY2t1cA== ssh:was2-backup-yubikey"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSdP4Ns3qpLjM0Pe9HvGjYhkjL6aYrDpDTed3BxM0tG backupkey@utility-key"
      ];
    };
    bootstrap = {
      openssh.authorizedKeys.keys = [
        "no-touch-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOydfhxPGVM4CNDD2r9rG2hwoOgfzz0AArSWw+jbreSuAAAAIHNzaDp3YXMyLXByaW1hcnkteXViaWtleS1ub3RvdWNo ssh:was2-primary-yubikey-notouch"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMyCcp/ezq5aPGqeeQK17aJOikDkBo/+R4Wgv/BlzndIAAAAGHNzaDp3YXMyLXByaW1hcnkteXViaWtleQ== ssh:was2-primary-yubikey"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILfEJ+lwOpxRMH+7u4TnLl7opRcclz8QosUzCcNDbPhuAAAAEnNzaDp5dWJpa2V5LWJhY2t1cA== ssh:was2-backup-yubikey"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSdP4Ns3qpLjM0Pe9HvGjYhkjL6aYrDpDTed3BxM0tG backupkey@utility-key"
      ];
      isNormalUser = true;
      initialPassword = "was2";
      extraGroups = [ "wheel" ];
    };
  };

  # Agenix config
  age = { 
    ageBin = "PATH=${pkgs.age-plugin-yubikey}/bin:$PATH ${pkgs.age}/bin/age";
    secrets = {
      wireguard-endpoint-guest-v4 = { 
        file = ./secrets/wireguard/guest/endpoints/v4.age; 
        mode = "0400";
      };
      wireguard-endpoint-guest-v6 = {
        file = ./secrets/wireguard/guest/endpoints/v6.age; 
        mode = "0400";
      };
      wireguard-key-guest = {
        file = ./secrets/wireguard/guest/key.age;
        mode = "0400";
      };
    };
  };

  # Programs / Packages #######################################################
  environment.systemPackages = with pkgs; with inputs; [
    neovim
    wget
    git
    curl
    usbutils
    libimobiledevice
    yubikey-manager
    yubico-pam
    home-manager.packages."${system}".default
    age
    age-plugin-yubikey
    agenix.packages."${system}".default
  ];

  # Services ##################################################################
  services.openssh.enable = true;
  services.usbmuxd.enable = true;

  # Networking ################################################################
  networking.useDHCP = lib.mkDefault true;

  networking.wg-quick.interfaces = 
  let
    publicKey = "8bvv1RX1uRXTKS0uQAN0PbaesG8A8XcENHuugWETlDY=";
    privateKeyPath = config.age.secrets.wireguard-key-guest.path;
    endpoint-v4-path = config.age.secrets.wireguard-endpoint-guest-v4.path;
    endpoint-v6-path = config.age.secrets.wireguard-endpoint-guest-v6.path;
    clientIP-v4 = "192.168.90.199/24";
    clientIP-v6 = "2600:1700:1ae8:938::eeee:9/64";
    
    dns-v4 = "192.168.10.252";
    dns-v6 = "fc38:5c79:6c89:10::fff:1";
  in
  {
    was2-boostrap-v4 = {
      autostart = true;
      address = [ clientIP-v4 ];
      dns = [ dns-v4 ];
      mtu = 1374;
      privateKeyFile = privateKeyPath;
      postUp = with pkgs; ''${wireguard-tools}/bin/wg set "was2-bootstrap-v4" peer ${publicKey} endpoint $(cat ${endpoint-v4-path})'';
      peers = [
        {
          publicKey = publicKey;
          allowedIPs = [ "0.0.0.0/0" ];
          persistentKeepalive = 25;
        }
      ];        
    };
    was2-boostrap-v6 = {
      autostart = true;
      address = [ clientIP-v6 ];
      dns = [ dns-v6 ];
      mtu = 1374;
      privateKeyFile = privateKeyPath;
      postUp = with pkgs; ''${wireguard-tools}/bin/wg set "was2-bootstrap-v4" peer ${publicKey} endpoint $(cat ${endpoint-v6-path})'';
      peers = [
        {
          publicKey = publicKey;
          allowedIPs = [ "::/0" ];
          persistentKeepalive = 25;
        }
      ];        
    };
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.stateVersion = "24.05";
}
