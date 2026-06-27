{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stc = {
      url = "github:gfriloux/stc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    astropath = {
      url = "github:gfriloux/astropath";
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
          inputs.stc.homeModules.cogitator-enginseer
          inputs.stc.homeModules.cogitator-desktop
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
