{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.opx-authd;
  configFormat = pkgs.formats.json { };
in
{
  options.services.opx-authd = {
    enable = mkEnableOption "opx-authd multi-backend secret daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.opx;
      description = "The opx package to use";
    };

    backend = mkOption {
      type = types.enum [
        "opcli"
        "vault"
        "bao"
        "multi"
        "fake"
      ];
      default = "opcli";
      description = "Backend to use for secret retrieval";
    };

    sessionTimeout = mkOption {
      type = types.int;
      default = 8;
      description = "Session idle timeout in hours (0 to disable)";
    };

    enableSessionLock = mkOption {
      type = types.bool;
      default = true;
      description = "Enable session idle timeout and locking";
    };

    lockOnAuthFailure = mkOption {
      type = types.bool;
      default = true;
      description = "Lock session on authentication failures";
    };

    enableAuditLog = mkOption {
      type = types.bool;
      default = false;
      description = "Enable structured audit logging to file";
    };

    auditLogRetentionDays = mkOption {
      type = types.int;
      default = 30;
      description = "Number of days to keep audit logs (0 = keep all)";
    };

    ttl = mkOption {
      type = types.int;
      default = 120;
      description = "Cache TTL in seconds";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose logging";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional arguments to pass to opx-authd";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file containing secrets (VAULT_TOKEN, etc.)";
    };

    policy = mkOption {
      type = types.nullOr configFormat.type;
      default = null;
      description = "Access control policy configuration";
      example = {
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
  };

  config = mkIf cfg.enable {
    # Install the package
    home.packages = [ cfg.package ];

    # Create policy file if specified
    xdg.configFile."opx-authd/policy.json" = mkIf (cfg.policy != null) {
      source = configFormat.generate "policy.json" cfg.policy;
    };

    # Configure launchd service for macOS
    launchd.agents.opx-authd = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments =
          [
            "${cfg.package}/bin/opx-authd"
            "--backend=${cfg.backend}"
            "--session-timeout=${toString cfg.sessionTimeout}"
            "--ttl=${toString cfg.ttl}"
            "--audit-log-retention-days=${toString cfg.auditLogRetentionDays}"
          ]
          ++ optional cfg.enableSessionLock "--enable-session-lock"
          ++ optional cfg.lockOnAuthFailure "--lock-on-auth-failure"
          ++ optional cfg.enableAuditLog "--enable-audit-log"
          ++ optional cfg.verbose "--verbose"
          ++ cfg.extraArgs;

        KeepAlive = true;
        RunAtLoad = true;

        StandardOutPath = "${config.home.homeDirectory}/.local/share/opx-authd/opx-authd.log";
        StandardErrorPath = "${config.home.homeDirectory}/.local/share/opx-authd/opx-authd.error.log";

        EnvironmentVariables = mkIf (cfg.environmentFile != null) {
          # Load environment from file
          ENVIRONMENT_FILE = cfg.environmentFile;
        };
      };
    };

    # Configure systemd service for Linux
    systemd.user.services.opx-authd = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "opx-authd multi-backend secret daemon";
        After = [ "default.target" ];
      };

      Service = {
        ExecStart =
          "${cfg.package}/bin/opx-authd"
          + " --backend=${cfg.backend}"
          + " --session-timeout=${toString cfg.sessionTimeout}"
          + " --ttl=${toString cfg.ttl}"
          + " --audit-log-retention-days=${toString cfg.auditLogRetentionDays}"
          + optionalString cfg.enableSessionLock " --enable-session-lock"
          + optionalString cfg.lockOnAuthFailure " --lock-on-auth-failure"
          + optionalString cfg.enableAuditLog " --enable-audit-log"
          + optionalString cfg.verbose " --verbose"
          + optionalString (cfg.extraArgs != [ ]) " ${concatStringsSep " " cfg.extraArgs}";

        Restart = "on-failure";
        RestartSec = "5";

        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
