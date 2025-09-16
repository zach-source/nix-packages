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

        opx = pkgs.buildGoModule rec {
          pname = "opx";
          version = "0.1.2";

          src = pkgs.fetchFromGitHub {
            owner = "zach-source";
            repo = "opx";
            rev = "v${version}";
            sha256 = "0000000000000000000000000000000000000000000000000000"; # TODO: Update
          };

          vendorHash = null; # Update when dependencies are added

          # Enable CGO for macOS Security framework integration
          CGO_ENABLED = if pkgs.stdenv.isDarwin then "1" else "0";

          nativeBuildInputs =
            with pkgs;
            [
              go
            ]
            ++ lib.optionals stdenv.isDarwin [
              darwin.apple_sdk.frameworks.Security
              darwin.apple_sdk.frameworks.CoreFoundation
            ];

          # Build both binaries
          subPackages = [
            "cmd/opx-authd"
            "cmd/opx"
          ];

          ldflags = [
            "-s"
            "-w"
            "-X main.version=${version}"
          ];

          # Install both binaries
          postInstall = ''
            # Binaries are already installed by buildGoModule
            echo "opx and opx-authd installed"
          '';

          meta = with pkgs.lib; {
            description = "Multi-backend secret batching daemon with advanced security";
            homepage = "https://github.com/zach-source/opx";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.darwin; # macOS only for now due to Security framework
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
              darwin.apple_sdk.frameworks.Security
              darwin.apple_sdk.frameworks.CoreFoundation
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
