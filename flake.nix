{
  description = "System configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-emoji = {
      url = "github:samuelngs/apple-emoji-linux/v1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kwin-better-blur = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      catpaws = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          inputs.chaotic.nixosModules.nyx-cache
          inputs.chaotic.nixosModules.nyx-overlay
          inputs.chaotic.nixosModules.nyx-registry
          ./system
          home-manager.nixosModules.home-manager
          {
            home-manager.sharedModules = [
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.zen-browser.homeModules.twilight
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.brunostjohn = import ./home;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
      maintenance = catpaws.pkgs.writeShellApplication {
        name = "nixos-maintenance";
        runtimeInputs = with catpaws.pkgs; [
          coreutils
          git
          gnugrep
          jq
          nix
          nixos-rebuild
          util-linux
        ];
        text = builtins.readFile ./scripts/nixos-maintenance.sh;
      };
      updateAiDesktops = catpaws.pkgs.writeShellApplication {
        name = "update-ai-desktops";
        runtimeInputs = with catpaws.pkgs; [
          coreutils
          curl
          gawk
          gnused
          nix
        ];
        text = builtins.readFile ./scripts/update-ai-desktops.sh;
      };
    in
    {
      nixosConfigurations.catpaws = catpaws;

      packages.${system} = {
        main-kernel = catpaws.config.boot.kernelPackages.kernel;
        rescue-kernel = catpaws.pkgs.linuxPackages_cachyos-lts.kernel;
        nixos-maintenance = maintenance;
        update-ai-desktops = updateAiDesktops;

        # Also reachable through home/ai.nix; exposed here so a pin bump can be
        # built and its payload audits exercised without a full rebuild.
        claude-desktop = catpaws.pkgs.callPackage ./packages/claude-desktop.nix { };
        chatgpt-desktop = catpaws.pkgs.callPackage ./packages/chatgpt-desktop.nix { };
      };

      apps.${system} = {
        nixos-maintenance = {
          type = "app";
          program = "${maintenance}/bin/nixos-maintenance";
          meta.description = "Cache-guarded NixOS rebuild and update helper";
        };
        update-ai-desktops = {
          type = "app";
          program = "${updateAiDesktops}/bin/update-ai-desktops";
          meta.description = "Bump the pinned Claude Desktop and ChatGPT Desktop builds";
        };
      };
    };
}
