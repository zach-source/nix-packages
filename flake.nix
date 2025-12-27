{
  description = "Nix flakes for utility tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nixfleet = pkgs.stdenv.mkDerivation rec {
          pname = "nixfleet";
          version = "0.1.5"; # nixfleet

          src =
            let
              selectSystem =
                if pkgs.stdenv.isDarwin then
                  if pkgs.stdenv.isAarch64 then
                    {
                      url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-darwin-arm64.tar.gz";
                      sha256 = "ec06100a2391a90dc3f23954612538be21f83c171d9cbaebfd66e13aff040e8e"; # darwin-arm64
                      binaryName = "nixfleet-darwin-arm64";
                    }
                  else
                    {
                      url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-darwin-amd64.tar.gz";
                      sha256 = "565cd04f9c8f29b36f96cfde82606ba129b240c9cde6d756dd55098eb25f7d42"; # darwin-amd64
                      binaryName = "nixfleet-darwin-amd64";
                    }
                else if pkgs.stdenv.isAarch64 then
                  {
                    url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-linux-arm64.tar.gz";
                    sha256 = "9577c7b0032f0ee66ab72a15cc3ed061c0bb248f1ff438f8819969f63532ed6c"; # linux-arm64
                    binaryName = "nixfleet-linux-arm64";
                  }
                else
                  {
                    url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-linux-amd64.tar.gz";
                    sha256 = "24e1c3f50be0b1452d16aadb14ae816a9b4bbd24d94cd2b72ac0a0323d5c65cb"; # linux-amd64
                    binaryName = "nixfleet-linux-amd64";
                  };
            in
            pkgs.fetchurl {
              inherit (selectSystem) url sha256;
            };

          binaryName =
            if pkgs.stdenv.isDarwin then
              if pkgs.stdenv.isAarch64 then "nixfleet-darwin-arm64" else "nixfleet-darwin-amd64"
            else if pkgs.stdenv.isAarch64 then
              "nixfleet-linux-arm64"
            else
              "nixfleet-linux-amd64";

          unpackPhase = ''
            runHook preUnpack
            mkdir -p source
            cd source
            tar -xzf $src
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp ${binaryName} $out/bin/nixfleet
            chmod +x $out/bin/nixfleet
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Fleet management CLI for deploying Nix configurations to non-NixOS hosts";
            homepage = "https://github.com/zach-source/nix-fleet";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

      in
      {
        packages = {
          inherit nixfleet;
          default = nixfleet;
        };

        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              go
              gopls
              golangci-lint
            ]
            ++ lib.optionals stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.CoreFoundation
            ];

          shellHook = ''
            echo "Development environment for nix-packages"
            echo "Available tools: go, gopls, golangci-lint"
          '';
        };

      }
    );
}
