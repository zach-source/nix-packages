# Home Manager module for claude-mon
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.claude-mon or { };

  enabled = cfg.enable or false;

  dataDir = cfg.dataDir or "${config.xdg.dataHome}/claude-mon";

  package = pkgs.callPackage ../. {
    inherit pkgs;
  };

in
{
  options = {
    services.claude-mon = {
      enable = mkEnableOption "claude-mon daemon and CLI";

      dataDir = mkOption {
        type = types.str;
        default = "${config.xdg.dataHome}/claude-mon";
        description = "Directory for claude-mon data (SQLite database, logs, etc.)";
      };

      autoStart = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to start the claude-mon daemon automatically at login";
      };

      socketPath = mkOption {
        type = types.str;
        default = "/tmp/claude-mon-daemon.sock";
        description = "Path to the daemon Unix socket";
      };

      querySocketPath = mkOption {
        type = types.str;
        default = "/tmp/claude-mon-query.sock";
        description = "Path to the query Unix socket";
      };
    };
  };

  config = mkIf enabled {
    # Install claude-mon package
    home.packages = [ package ];

    # Create data directory
    xdg.dataFile."claude-mon" = {
      target = "${config.xdg.dataHome}/claude-mon";
      recursive = true;
    };

    # Set up systemd user service for Linux
    systemd.user.services.claude-mon = mkIf (pkgs.stdenv.isLinux && cfg.autoStart) {
      Unit = {
        Description = "claude-mon daemon - Persistent Claude Code activity tracking";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = "${package}/bin/claude-mon daemon start";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "CLAUDE_MON_DATA_DIR=${dataDir}"
          "CLAUDE_MON_DAEMON_SOCKET=${cfg.socketPath}"
          "CLAUDE_MON_QUERY_SOCKET=${cfg.querySocketPath}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Set up launchd service for macOS
    launchd.agents.claude-mon = mkIf (pkgs.stdenv.isDarwin && cfg.autoStart) {
      enable = true;
      config = {
        ProgramArguments = [
          "${package}/bin/claude-mon"
          "daemon"
          "start"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${dataDir}/claude-mon.log";
        StandardErrorPath = "${dataDir}/claude-mon-error.log";
        EnvironmentVariables = {
          CLAUDE_MON_DATA_DIR = dataDir;
          CLAUDE_MON_DAEMON_SOCKET = cfg.socketPath;
          CLAUDE_MON_QUERY_SOCKET = cfg.querySocketPath;
        };
      };
    };

    # Add claude-mon to PATH
    home.sessionPath = [ "${package}/bin" ];

    # Create alias for short name
    home.shellAliases.clmon = "claude-mon";
  };
}
