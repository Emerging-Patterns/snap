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
  inputs.bolt = {
    url = "github:Emerging-Patterns/bolt";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.bend.follows = "bend";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      llvm = pkgs.llvmPackages_19;
      bend = inputs.bend.packages.${system}.default;
      ez = inputs.ez.packages.${system}.default;
      bolt = inputs.bolt.packages.${system}.default;

      bend-cc = pkgs.writeShellScriptBin "bend-cc" ''
        exec ${llvm.clang-unwrapped}/bin/clang \
          -resource-dir ${llvm.clang}/resource-root \
          --ld-path=/usr/bin/ld \
          -Wl,--dynamic-linker=/lib64/ld-linux-x86-64.so.2 "$@"
      '';

      demo = pkgs.stdenv.mkDerivation {
        pname = "snap-demo";
        version = "0.1.0";
        src = self;
        nativeBuildInputs = [ bend ];
        buildPhase = ''
          bend examples/demo/main.bend -o demo.bin
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp demo.bin $out/bin/demo
        '';
        meta = {
          description = "Fixture that runs programs through snap";
          license = pkgs.lib.licenses.mit;
          mainProgram = "demo";
        };
      };

      # a writable copy of this tree: `ez test` writes `.ez/`
      proofs = pkgs.runCommand "snap-proofs"
        {
          nativeBuildInputs = [ ez ];
          EZ_DEADLINE = "0";
        }
        ''
          cp -r ${self} src
          chmod -R u+w src
          cd src
          ez test
          echo ok > $out
        '';

      lint = pkgs.runCommand "snap-lint"
        {
          nativeBuildInputs = [ bolt ];
        }
        ''
          cp -r ${self} src
          chmod -R u+w src
          cd src
          bolt
          echo ok > $out
        '';
    in {
      packages.${system} = { inherit bend demo bend-cc ez bolt; default = demo; };
      apps.${system}.default = { type = "app"; program = "${demo}/bin/demo"; };
      checks.${system} = { inherit demo proofs lint; };
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [ bend bend-cc ez bolt ];
        shellHook = "export CC=bend-cc";
      };
    };
}
