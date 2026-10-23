{
  description = "snap: program runner for Bend 2";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # bendlang/bend's flake at the commit that packages 2.0.38 (the v2.0.38 tag
  # may still package 2.0.37)
  inputs.bend = {
    url = "github:bendlang/bend/042e797ebd1cfc060603e2682879909fe86fa8c2";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # Interim: ez does not build on bend 2.0.38 yet, so ez (and the bolt it
  # builds, which mkLint runs) stay on the bend ez's own flake.lock records,
  # 2.0.36, while snap builds and proves on 2.0.38. A tooling pass puts
  # `inputs.bend.follows = "bend"` and ez.mkProofs back once ez releases on
  # 2.0.38 (bolt's `--gpu off` then goes inside `+RTS ... -RTS`).
  inputs.ez = {
    url = "github:Emerging-Patterns/ez";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.bend.url = "github:bendlang/bend/eebc18cd04daeade06c3f68c3c96c1faefd3462f";
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
        version = "1.3.0"; # x-release-please-version
        entry = "examples/demo/main.bend";
      };
    in {
      packages.${system} = { inherit bend demo bend-cc; ez = ezBin; inherit bolt; default = demo; };
      apps.${system}.default = { type = "app"; program = "${demo}/bin/demo"; };
      checks.${system} = {
        inherit demo;
        # every PROOF.bend must print ALL PROOFS CHECK, on this flake's bend
        # (in place of ez.mkProofs while ez runs on 2.0.36)
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
