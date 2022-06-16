{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    discord-overlay = {
      url = "github:InternetUnexplorer/discord-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    discocss.url = "github:mlvzk/discocss/flake";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

  };
  outputs =
    inputs@{ self
    , nixpkgs
    , home-manager
    , nur
    , discord-overlay
    , discocss
    , ...
    }:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      lib = nixpkgs.lib;

      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [
            { networking.hostName = hostname; }
            (./. + "/hosts/${hostname}/system.nix")
            (./. + "/hosts/${hostname}/hardware-configuration.nix")
            ./modules/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useUserPackages = true;
                useGlobalPkgs = true;
                extraSpecialArgs = { inherit inputs; };
                users.battlechicken = (./. + "/hosts/${hostname}/user.nix");
                sharedModules = [ discocss.hmModule ];
              };
              nixpkgs.overlays = [
                nur.overlay
                discord-overlay.overlay
                inputs.neovim-nightly-overlay.overlay
              ];
            }

          ];
          specialArgs = { inherit inputs; };
        };
    in
    {
      nixosConfigurations = {
        Entertainer = mkSystem inputs.nixpkgs "x86_64-linux" "Entertainer";
        boxie = mkSystem inputs.nixpkgs "x86_64-linux" "boxie";
      };

      devShell.${system} = pkgs.mkShell {
        packages = [ pkgs.nixpkgs-fmt ];
        inherit (self.checks.${system}.pre-commit-check) shellHook;
      };

      checks.${system}.pre-commit-check =
        inputs.pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks.nixpkgs-fmt.enable = true;
          hooks.shellcheck.enable = true;
        };
    };
}
