{
  outputs = {
    self,
    nixpkgs,
    flake-parts,
    pre-commit-hooks-nix,
    std,
    ...
  } @ inputs: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    nixpkgsConfig = {
      allowUnsupportedSystem = true;
    };
    std_flake_out =
      std.growOn {
        inherit inputs nixpkgsConfig;
        cellsFrom = ./nix;

        cellBlocks = with std.blockTypes; [
          (runnables "apps")
          (installables "packages")
          (pkgs "pkgs")
          (devshells "devshells")
        ];
      }
      {
        packages = std.harvest inputs.self [["local" "packages"] ["local" "pkgs"]];
        devShells = std.harvest inputs.self ["local" "devshells"];
      };
    flake_parts_out = flake-parts.lib.mkFlake {inherit inputs;} {
      flake = {inherit std_flake_out;};
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.std.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = supportedSystems;
      perSystem = {
        config,
        inputs',
        lib,
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config = nixpkgsConfig;
        };
        pre-commit.settings = {
          hooks = {
            # C
            clang-format.enable = true;
            clang-tidy = {
              enable = true;
              entry = "clang-tidy --fix -checks=bugprone-*,clang-analyzer-*,cert-*,concurrency-*,misc-*,modernize-*,performance-*,portability-*,readability-*,-readability-identifier-length";
            };

            # Nix
            alejandra.enable = true;
            deadnix = {
              enable = true;
              settings = {
                noUnderscore = true;
                noLambdaPatternNames = true;
              };
            };
            statix.enable = true;
            typos = {
              enable = true;
              settings = {
                configuration = ''
                  [default]
                  check-filename = false
                  extend-ignore-re = [
                    "PNGs",
                    "ba"
                  ]

                  [type.nb]
                  extend-glob = ["*.nb"]
                  check-file = false
                  [type.md]
                  extend-glob = ["*.md"]
                  check-file = false
                '';
                locale = "en-us";
              };
            };
          };
        };
        devShells = let
          inherit (std_flake_out.packages.${system}) epsteinlib;
        in rec {
          epstein_devshell = pkgs.mkShell {
            inherit (config.pre-commit.devShell) shellHook nativeBuildInputs;

            inputsFrom = [
              std_flake_out.devShells.${system}.std
              epsteinlib
            ];
            packages = [
              epsteinlib
            ];
          };
          default = epstein_devshell;
        };
        packages = std_flake_out.packages.${system};

        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            # JSON
            biome.enable = true;
            # C
            clang-format.enable = true;
            # Nix
            alejandra.enable = true;
          };
        };
      };
    };
  in
    std_flake_out // flake_parts_out;

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-stable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    pre-commit-hooks-nix.url = "github:cachix/git-hooks.nix";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    std = {
      url = "github:divnix/std";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        devshell.url = "github:numtide/devshell";
        devshell.follows = "devshell";
      };
    };
  };
}
