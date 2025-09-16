# Nix Packages and Home Manager Modules

A collection of Nix flakes and home-manager modules for utility tools and applications.

## Installation

### Using Nix Flakes

```bash
# Install opx directly
nix run github:zach-source/nix-packages#opx

# Install to profile
nix profile install github:zach-source/nix-packages#opx
```

### Home Manager Integration

Add to your `home.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    utils.url = "github:zach-source/nix-packages";
  };

  outputs = { nixpkgs, home-manager, utils, ... }: {
    homeConfigurations."your-username" = home-manager.lib.homeManagerConfiguration {
      modules = [
        utils.homeManagerModules.opx
        {
          services.opx-authd = {
            enable = true;
            backend = "multi";
            enableAuditLog = true;
            sessionTimeout = 8;
            
            policy = {
              allow = [
                {
                  path = "/usr/bin/kubectl";
                  refs = [ "op://Production/k8s/*" ];
                  require_signed = true;
                }
              ];
              default_deny = true;
            };
          };
        }
      ];
    };
  };
}
```

## Available Packages

### opx - Multi-Backend Secret Daemon

**Features:**
- Multi-backend secret access (1Password + Vault + Bao)
- Advanced security with process verification and audit logging
- Session management with configurable timeouts
- Policy-based access control

**Configuration Options:**
- `backend`: Backend type (opcli, vault, bao, multi, fake)
- `sessionTimeout`: Session idle timeout in hours
- `enableAuditLog`: Enable structured audit logging
- `policy`: Access control policy configuration
- `environmentFile`: Path to environment file with secrets

**Usage:**
```bash
# Start service
systemctl --user start opx-authd  # Linux
# or it starts automatically with home-manager

# Use client
opx login 1password --account=YOUR_ACCOUNT
opx read "op://vault/item/field"
```

## Development

```bash
# Enter development shell
nix develop github:zach-source/nix-packages

# Build locally
nix build github:zach-source/nix-packages#opx
```

## Adding New Packages

To add a new utility package:

1. Add package definition to `flake.nix`
2. Create home-manager module in `modules/` if needed
3. Update documentation
4. Test the package

## Supported Platforms

- **macOS**: Full support with Security framework integration
- **Linux**: Planned support (currently macOS-only due to Security framework)

## Links

- [Main opx Repository](https://github.com/zach-source/opx)
- [Nix Documentation](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)