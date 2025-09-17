{
  description = "Nix flakes and home-manager modules for utility tools";

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

        opx = pkgs.stdenv.mkDerivation rec {
          pname = "opx";
          version = "0.1.2";

          # Use pre-built binaries from GitHub releases
          src = pkgs.fetchurl {
            url = "https://github.com/zach-source/opx/releases/download/v${version}/opx-server_v${version}_darwin_arm64.tar.gz";
            sha256 = "sha256-Ns2+1TaC6NRxNTBpgFPZxeU1a8bEVrEgUfBTB4PYV1A=";
          };

          # No build dependencies needed - using pre-built binaries
          nativeBuildInputs = [ pkgs.installShellFiles ];

          # Also download client binary
          clientSrc = pkgs.fetchurl {
            url = "https://github.com/zach-source/opx/releases/download/v${version}/opx-client_v${version}_darwin_arm64.tar.gz";
            sha256 = "sha256-5SLGiiKYMgzmvSSaVm7aP91wR1Nibk2myLg=";
          };

          # Extract and install both binaries
          unpackPhase = ''
            runHook preUnpack

            # Extract server binary
            tar -xzf $src

            # Extract client binary  
            mkdir -p client_tmp
            tar -xzf $clientSrc -C client_tmp
            mv client_tmp/opx .

            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp opx-authd $out/bin/opx-authd
            cp opx $out/bin/opx

            chmod +x $out/bin/opx-authd
            chmod +x $out/bin/opx

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Multi-backend secret batching daemon with advanced security";
            homepage = "https://github.com/zach-source/opx";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.darwin; # macOS only - uses pre-built binaries
          };
        };

      in
      {
        packages = {
          inherit opx;
          default = opx;
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
            echo "Development environment for opx and other utilities"
            echo "Available tools: go, gopls, golangci-lint"
          '';
        };

        # Home Manager module will be added here
        homeManagerModules = {
          opx = ./modules/opx.nix;
        };
      }
    );
}
