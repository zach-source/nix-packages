{
  description = "Nix flakes for utility tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Steve Yegge's AI coding tools
    gastown-src = {
      url = "github:steveyegge/gastown";
      flake = false;
    };
    beads-src = {
      url = "github:steveyegge/beads";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      gastown-src,
      beads-src,
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

        claude-mon = pkgs.stdenv.mkDerivation rec {
          pname = "claude-mon";
          version = "0.1.0"; # claude-mon

          src =
            let
              selectSystem =
                if pkgs.stdenv.isDarwin then
                  if pkgs.stdenv.isAarch64 then
                    {
                      url = "https://github.com/zach-source/claude-mon/releases/download/v${version}/claude-mon-darwin-arm64.tar.gz";
                      sha256 = "0000000000000000000000000000000000000000000000000000000000000000"; # darwin-arm64 # claude-mon
                      binaryName = "claude-mon-darwin-arm64";
                    }
                  else
                    {
                      url = "https://github.com/zach-source/claude-mon/releases/download/v${version}/claude-mon-darwin-amd64.tar.gz";
                      sha256 = "0000000000000000000000000000000000000000000000000000000000000000"; # darwin-amd64 # claude-mon
                      binaryName = "claude-mon-darwin-amd64";
                    }
                else if pkgs.stdenv.isAarch64 then
                  {
                    url = "https://github.com/zach-source/claude-mon/releases/download/v${version}/claude-mon-linux-arm64.tar.gz";
                    sha256 = "0000000000000000000000000000000000000000000000000000000000000000"; # linux-arm64 # claude-mon
                    binaryName = "claude-mon-linux-arm64";
                  }
                else
                  {
                    url = "https://github.com/zach-source/claude-mon/releases/download/v${version}/claude-mon-linux-amd64.tar.gz";
                    sha256 = "0000000000000000000000000000000000000000000000000000000000000000"; # linux-amd64 # claude-mon
                    binaryName = "claude-mon-linux-amd64";
                  };
            in
            pkgs.fetchurl {
              inherit (selectSystem) url sha256;
            };

          binaryName =
            if pkgs.stdenv.isDarwin then
              if pkgs.stdenv.isAarch64 then "claude-mon-darwin-arm64" else "claude-mon-darwin-amd64"
            else if pkgs.stdenv.isAarch64 then
              "claude-mon-linux-arm64"
            else
              "claude-mon-linux-amd64";

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
            cp ${binaryName} $out/bin/claude-mon
            chmod +x $out/bin/claude-mon
            # Create symlink for short name
            ln -s $out/bin/claude-mon $out/bin/clmon
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "TUI application for watching Claude Code edits in real-time and managing prompts";
            homepage = "https://github.com/zach-source/claude-mon";
            license = licenses.mit;
            maintainers = [ ];
            platforms = platforms.unix;
          };
        };

        # Beads - git-backed graph issue tracker for AI coding agents
        beads = pkgs.buildGoModule {
          pname = "beads";
          version = "0.44.0"; # beads

          src = beads-src;

          vendorHash = "sha256-YU+bRLVlWtHzJ1QPzcKJ70f+ynp8lMoIeFlm+29BNPE="; # beads

          subPackages = [ "cmd/bd" ];

          nativeCheckInputs = [ pkgs.git ];

          # Some tests require git worktree features not available in sandbox
          doCheck = false;

          ldflags = [
            "-s"
            "-w"
            "-X main.version=0.44.0"
          ];

          meta = with pkgs.lib; {
            description = "Distributed, git-backed graph issue tracker for AI coding agents";
            homepage = "https://github.com/steveyegge/beads";
            license = licenses.asl20;
            maintainers = [ ];
            mainProgram = "bd";
          };
        };

        # Gastown - multi-agent orchestration system for Claude Code
        gastown = pkgs.buildGoModule {
          pname = "gastown";
          version = "0.1.0"; # gastown

          src = gastown-src;

          vendorHash = "sha256-ripY9vrYgVW8bngAyMLh0LkU/Xx1UUaLgmAA7/EmWQU="; # gastown

          subPackages = [ "cmd/gt" ];

          ldflags = [
            "-s"
            "-w"
          ];

          meta = with pkgs.lib; {
            description = "Multi-agent orchestration system for Claude Code";
            homepage = "https://github.com/steveyegge/gastown";
            license = licenses.asl20;
            maintainers = [ ];
            mainProgram = "gt";
          };
        };

      in
      {
        packages = {
          inherit nixfleet;
          inherit claude-mon;
          inherit beads;
          inherit gastown;
          default = nixfleet;
        };

        homeManagerModules = {
          claude-mon = import ./modules/claude-mon.nix;
          default = claude-mon;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            golangci-lint
          ];

          shellHook = ''
            echo "Development environment for nix-packages"
            echo "Available tools: go, gopls, golangci-lint"
          '';
        };

      }
    );
}
