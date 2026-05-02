{
  description = "Helix Steel plugin for fcitx5 focus and mode switching";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    steel.url = "git+https://github.com/mattwparas/steel.git";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { pkgs, system, ... }:
        let
          overlays = [ inputs.rust-overlay.overlays.default ];
          pkgsWithRust = import inputs.nixpkgs {
            inherit system overlays;
          };
          rustToolchain = pkgsWithRust.rust-bin.stable.latest.default.override {
            extensions = [
              "clippy"
              "rust-analyzer"
              "rust-src"
              "rustfmt"
            ];
          };
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [
              rustToolchain
              inputs.steel.packages.${system}.steel
              pkgs.dbus
              pkgs.pkg-config
            ];
          };
        };
    };
}
