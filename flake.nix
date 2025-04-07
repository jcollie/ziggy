{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zon2nix = {
      url = "github:jcollie/zon2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    zon2nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        packages = {
          ziggy = let
            zig_hook = pkgs.zig_0_14.hook.overrideAttrs {
              zig_default_flags = "-Dcpu=baseline -Doptimize=ReleaseFast --color off";
            };
          in
            pkgs.stdenv.mkDerivation {
              name = "ziggy";
              version = "0.0.0";
              outputs = [
                "out"
                "tree_sitter"
              ];
              src = ./.;
              nativeBuildInputs = [zig_hook];
              zigBuildFlags = [
                "--system"
                "${pkgs.callPackage ./build.zig.zon.nix {}}"
              ];
              postInstall = ''
                mkdir $tree_sitter
                cp -R tree-sitter-ziggy $tree_sitter/ziggy
                cp -R tree-sitter-ziggy-schema $tree_sitter/ziggy_schema
              '';
              meta = {
                mainProgram = "ziggy";
              };
            };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.zig_0_14
            zon2nix.packages.${system}.zon2nix
          ];
        };
      }
    );
}
