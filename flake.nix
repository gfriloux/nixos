{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cli = {
      url = "github:gfriloux/nix-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gui = {
      url = "github:gfriloux/nix-gui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pgpilot = {
      url = "github:gfriloux/pgpilot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      systems = ["x86_64-linux"];
      inherit inputs;

      src = ./.;

      snowfall = {
        root = ./.;

        namespace = "kuri";

        systems.modules = with inputs; [
          sops-nix.nixosModules.sops
        ];

        homes.modules = with inputs; [
          inputs.nix-cli.homeModules.default
          inputs.nix-gui.homeModules.default
          inputs.sops-nix.homeManagerModules.sops
          inputs.pgpilot-flake.homeModules.pgpilot
        ];

        meta = {
          name = "kuri";
          title = "Adeptus Mechanicus";
        };
      };
    };
}
