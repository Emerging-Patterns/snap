{
  description = "snap: program runner for Bend 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.bend = {
    url = "github:bendlang/bend";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.ez = {
    url = "github:Emerging-Patterns/ez";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.bend.follows = "bend";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      ez = inputs.ez.lib.${system};
      ezBin = inputs.ez.packages.${system}.default;
      bend = inputs.bend.packages.${system}.default;
      bolt = ez.toolPackage { name = "bolt"; src = self; inherit bend; wrapFlags = [ "--gpu" "off" ]; };
      bend-cc = ez.bend-cc;
      demo = ez.mkPackage {
        inherit bend;
        src = self;
        pname = "demo";
        version = "1.0.0"; # x-release-please-version
        entry = "examples/demo/main.bend";
      };
    in {
      packages.${system} = { inherit bend demo bend-cc; ez = ezBin; inherit bolt; default = demo; };
      apps.${system}.default = { type = "app"; program = "${demo}/bin/demo"; };
      checks.${system} = {
        inherit demo;
        proofs = ez.mkProofs { ez = ezBin; src = self; };
        lint = ez.mkLint { src = self; };
      };
      devShells.${system}.default = ez.mkShell {
        src = self;
        packages = [ bend bend-cc ezBin ];
      };
    };
}
