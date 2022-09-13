{
  description = "A very basic flake";
  inputs = {
    godot-patches = {
      url = "github:virtual-puppet-project/godot-patches";
      flake = false;
    };
    godot-stdout-stderr-intercept = {
      url = "github:you-win/godot-stdout-stderr-intercept";
      flake = false;
    };
    youwin-godot-module = {
      url = "github:you-win/youwin-godot-module";
      flake = false;
    };
    vpuppr-godot-modules = {
      url = "github:virtual-puppet-project/vpuppr-godot-modules";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    {
      overlays.default = final: prev: {
        godot = final.callPackage ./build.nix {
          extraModules = with inputs; [
            godot-patches
            godot-stdout-stderr-intercept
            (final.fetchgit {
              # TODO: fix this after nix flakes gain support for git submodules
              url = "https://github.com/you-win/godot-toml";
              rev = "7e79ba0ab7ce4f2982f1956f5a4db4f56097ce69";
              fetchSubmodules = true;
              hash = "sha256-/JJA3eTwpWgyVMjsTMTiTCYO/xGXuCeU61dALyC8aB0=";
            })
            youwin-godot-module
            vpuppr-godot-modules
          ];
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system: rec{
      legacyPackages = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
      packages.default = legacyPackages.godot;
    });
}
