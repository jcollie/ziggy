{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    zon2nix = {
      url = "github:jcollie/zon2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      zon2nix,
      ...
    }:
    let
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      makePackages =
        system:
        import nixpkgs {
          inherit system;
        };
      forAllSystems = (function: nixpkgs.lib.genAttrs platforms (system: function (makePackages system)));
    in
    {
      packages = forAllSystems (pkgs: {
        ziggy = pkgs.stdenv.mkDerivation {
          name = "ziggy";
          version = "0.0.0";
          outputs = [
            "out"
            "tree_sitter"
          ];
          src = ./.;
          nativeBuildInputs = [ pkgs.zig_0_16 ];
          zigBuildFlags = [
            "--system"
            "${pkgs.callPackage ./build.zig.zon.nix { }}"
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
      });
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.zig_0_16
            zon2nix.packages.${pkgs.stdenv.hostPlatform.system}.zon2nix
          ];
        };
      });
    };

}
