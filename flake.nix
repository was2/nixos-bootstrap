{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  
    agenix = {
      url = "github:was2/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { nixpkgs, disko, agenix, ... } @inputs: rec {
    
    nixosModules.disko = disko;

    nixosConfigurations = {
      was2-bootstrap = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./bootstrap.nix
          ({lib, ...}: {
            networking.hostName = "set_host_name";
            was2.installDevice = lib.mkForce "|set_install_target|";
            was2.diskLayouts.lvm_on_luks.enable = true;
          })
        ];
      };
    };
  }; # outputs
}