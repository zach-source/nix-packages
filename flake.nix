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

        nixfleet = pkgs.stdenv.mkDerivation rec {
          pname = "nixfleet";
          version = "0.1.2"; # nixfleet

          src =
            let
              selectSystem =
                if pkgs.stdenv.isDarwin then
                  if pkgs.stdenv.isAarch64 then
                    {
                      url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-darwin-arm64.tar.gz";
                      sha256 = "03e86e7cbf64b130f95930b21167b68e6128306d0fe37c7828189beb79b204f5"; # darwin-arm64
                      binaryName = "nixfleet-darwin-arm64";
                    }
                  else
                    {
                      url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-darwin-amd64.tar.gz";
                      sha256 = "efe99874e1964a5fd0e31c1ca90132c65c85f5003f37e6a2e4938ff5a34ac341"; # darwin-amd64
                      binaryName = "nixfleet-darwin-amd64";
                    }
                else if pkgs.stdenv.isAarch64 then
                  {
                    url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-linux-arm64.tar.gz";
                    sha256 = "33ad5f546ab4452fd13562944ca885ea61499726e421547831e244681ccd42b4"; # linux-arm64
                    binaryName = "nixfleet-linux-arm64";
                  }
                else
                  {
                    url = "https://github.com/zach-source/nix-fleet/releases/download/v${version}/nixfleet-linux-amd64.tar.gz";
                    sha256 = "494b6f9421e55a263a0ee37d8ba2af5d692bfa487a5c27a20b968af489c8ec39"; # linux-amd64
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
          inherit opx nixfleet;
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
