{
  description = "snap: program runner for Bend 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # bendlang/bend's flake at the commit that packages 2.0.36 (the v2.0.36 tag
  # still packages 2.0.35)
  inputs.bend = {
    url = "github:bendlang/bend/eebc18cd04daeade06c3f68c3c96c1faefd3462f";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ez follows this flake's bend, so ez (and the bolt it builds) run on 2.0.36
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
      bolt = ez.toolPackage { name = "bolt"; src = self; wrapFlags = [ "--gpu" "off" ]; };
      bend-cc = ez.bend-cc;
      demo = ez.mkPackage {
        inherit bend;
        src = self;
        pname = "demo";
        version = "1.2.0"; # x-release-please-version
        entry = "examples/demo/main.bend";
      };
    in {
      packages.${system} = { inherit bend demo bend-cc; ez = ezBin; inherit bolt; default = demo; };
      apps.${system}.default = { type = "app"; program = "${demo}/bin/demo"; };
      checks.${system} = {
        inherit demo;
        # every PROOF.bend must print ALL PROOFS CHECK (ez prove)
        proofs = ez.mkProofs { ez = ezBin; src = self; };
        lint = ez.mkLint { src = self; };
      };
      devShells.${system}.default = ez.mkShell {
        src = self;
        packages = [ bend bend-cc ezBin ];
      };
    };
}
