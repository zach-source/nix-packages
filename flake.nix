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
          version = "0.7.0";

          # Use pre-built binaries from GitHub releases
          src = pkgs.fetchurl {
            url = "https://github.com/zach-source/opx/releases/download/v0.7.0/opx-server_v0.7.0_darwin_arm64_signed.tar.gz";
            sha256 = "eceed72b9191ee1563f75e18c43a94a666145939b03f3c7c9cbf3655dba55ae2";
          };

          # Build dependencies
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
                url = "https://github.com/zach-source/opx/releases/download/v0.7.0/opx-client_v0.7.0_darwin_arm64_signed.tar.gz";
                sha256 = "9604257826e3b5ab34818f988d543b228284a02ed3bdfd5c95f7b6dbf891846e";
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
