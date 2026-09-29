{
  description = "snap: program runner for Bend 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # bendlang/bend's flake at the commit that packages 2.0.34 (the v2.0.34 tag
  # still packages 2.0.33)
  inputs.bend = {
    url = "github:bendlang/bend/777ee0b55c485afdd7e68bd917b3d23a88d77371";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # ez and its bolt stay on the bend ez's own flake.lock records until ez
  # releases on 2.0.34, so ez's inputs.bend is pinned, not followed. The
  # package's own builds and its proofs (checks.proofs) run on 2.0.34.
  inputs.ez = {
    url = "github:Emerging-Patterns/ez";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.bend.url = "github:bendlang/bend/af569d4826913b2ce3557e9829ccad31fcf86f94";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      ez = inputs.ez.lib.${system};
      ezBin = inputs.ez.packages.${system}.default;
      bend = inputs.bend.packages.${system}.default;
      bolt = ez.toolPackage { name = "bolt"; src = self; wrapFlags = [ "--gpu" "off" ]; };
      bend-cc = ez.bend-cc;
      demo = ez.mkPackage {
        inherit bend;
        src = self;
        pname = "demo";
        version = "1.1.0"; # x-release-please-version
        entry = "examples/demo/main.bend";
      };
    in {
      packages.${system} = { inherit bend demo bend-cc; ez = ezBin; inherit bolt; default = demo; };
      apps.${system}.default = { type = "app"; program = "${demo}/bin/demo"; };
      checks.${system} = {
        inherit demo;
        # every PROOF.bend on this flake's bend: its first line must be
        # ALL PROOFS CHECK. ez.mkProofs comes back when ez runs on 2.0.34.
        proofs = pkgs.runCommand "snap-proofs" {
          nativeBuildInputs = [ bend ];
          BEND_LIB = ez.bendLib ./ez.lock.toml;
        } ''
          export HOME=$TMPDIR
          cp -r ${self} src && chmod -R u+w src && cd src
          for p in $(find . -name PROOF.bend -not -path './.ez/*' | sort); do
            first=$(cd "$(dirname "$p")" && bend "$(basename "$p")" | head -n 1)
            echo "$p: $first"
            [ "$first" = "ALL PROOFS CHECK" ] || exit 1
          done
          touch $out
        '';
        lint = ez.mkLint { src = self; };
      };
      devShells.${system}.default = ez.mkShell {
        src = self;
        packages = [ bend bend-cc ezBin ];
      };
    };
}
