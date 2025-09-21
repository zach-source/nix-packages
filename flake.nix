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
          version = "0.3.0";

          # Use pre-built binaries from GitHub releases
          src = pkgs.fetchurl {
            url = "https://github.com/zach-source/opx/releases/download/v${version}/opx-server_v${version}_darwin_arm64.tar.gz";
            sha256 = "3ebb0319758994c41e35222de3fa08663f8e0faf077521832eab93b27b81554a";
          };

          # No build dependencies needed - using pre-built binaries
          nativeBuildInputs = [ pkgs.installShellFiles ];

          # Custom unpack since archives contain files at root level
          unpackPhase = ''
            runHook preUnpack

            # Create a workspace directory
            mkdir -p source
            cd source

            # Extract server binary
            tar -xzf $src

            runHook postUnpack
          '';

          installPhase =
            let
              clientSrc = pkgs.fetchurl {
                url = "https://github.com/zach-source/opx/releases/download/v${version}/opx-client_v${version}_darwin_arm64.tar.gz";
                sha256 = "68b3f08f0c5d16de355fd51971f85794a5fb02de99628e99e6f079f7928e419d";
              };
            in
            ''
              runHook preInstall

              mkdir -p $out/bin

              # Install server binary (already extracted from src)
              cp opx-authd $out/bin/opx-authd
              chmod +x $out/bin/opx-authd

              # Extract and install client binary
              mkdir -p client_tmp
              tar -xzf ${clientSrc} -C client_tmp
              cp client_tmp/opx $out/bin/opx
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

      }
    )
    // {
      # Home Manager modules (system-agnostic)
      homeManagerModules = {
        opx = ./modules/opx.nix;
      };
    };
}
