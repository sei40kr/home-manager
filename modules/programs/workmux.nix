{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.workmux;

  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };

  workmuxBin = if cfg.package != null then "${cfg.package}/bin/workmux" else "workmux";

  mkCommand = status: "${workmuxBin} set-window-status ${status}";

  claudeCodeHooks = {
    UserPromptSubmit = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "working";
          }
        ];
      }
    ];
    Notification = [
      {
        matcher = "permission_prompt|elicitation_dialog";
        hooks = [
          {
            type = "command";
            command = mkCommand "waiting";
          }
        ];
      }
    ];
    PostToolUse = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "working";
          }
        ];
      }
    ];
    Stop = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "done";
          }
        ];
      }
    ];
  };

  geminiCliHooks = {
    BeforeAgent = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "working";
          }
        ];
      }
    ];
    Notification = [
      {
        matcher = "ToolPermission";
        hooks = [
          {
            type = "command";
            command = mkCommand "waiting";
          }
        ];
      }
    ];
    AfterTool = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "working";
          }
        ];
      }
    ];
    AfterAgent = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "done";
          }
        ];
      }
    ];
    SessionEnd = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "done";
          }
        ];
      }
    ];
  };

  codexHooks = {
    UserPromptSubmit = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "working";
          }
        ];
      }
    ];
    PostToolUse = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "working";
          }
        ];
      }
    ];
    Stop = [
      {
        hooks = [
          {
            type = "command";
            command = mkCommand "done";
          }
        ];
      }
    ];
  };

  opencodePluginSource = ''
    import type { Plugin } from '@opencode-ai/plugin';

    export const WorkmuxStatusPlugin: Plugin = async ({ $ }) => {
      // OpenCode can emit repeated `session.status busy` events for a single turn,
      // and can even emit a stale trailing `busy` after `idle` at the end. Track
      // per-session status so workmux only sees real transitions.
      const lastStatusBySession = new Map<string, string>();
      const acceptBusyBySession = new Map<string, boolean>();

      async function setStatus(
        sessionID: string | undefined,
        status: string,
      ) {
        if (!sessionID) {
          return;
        }

        const previous = lastStatusBySession.get(sessionID);
        // Ignore the final stale `busy` OpenCode sometimes emits after a session is
        // already done. The next user message re-arms `working` for the new turn.
        if (status === 'working' && acceptBusyBySession.get(sessionID) === false) {
          return;
        }
        if (previous === status) {
          return;
        }

        lastStatusBySession.set(sessionID, status);
        if (status === 'done') {
          acceptBusyBySession.set(sessionID, false);
        } else {
          acceptBusyBySession.set(sessionID, true);
        }

        await $`workmux set-window-status ''${status}`.quiet();
      }

      return {
        event: async ({ event }) => {
          if (event.type === 'message.updated' && event.properties.info.role === 'user') {
            acceptBusyBySession.set(event.properties.sessionID, true);
          }

          switch (event.type) {
            case 'session.status':
              if (event.properties.status.type === 'busy') {
                await setStatus(event.properties.sessionID, 'working');
              }
              if (event.properties.status.type === 'idle') {
                await setStatus(event.properties.sessionID, 'done');
              }
              break;
            case 'permission.asked':
            case 'question.asked':
              await setStatus(event.properties.sessionID, 'waiting');
              break;
            case 'permission.replied':
            case 'question.replied':
              await setStatus(event.properties.sessionID, 'working');
              break;
            case 'session.idle':
              await setStatus(event.properties.sessionID, 'done');
              break;
          }
        },
      };
    };
  '';

  opencodePackageJson = {
    private = true;
    dependencies = {
      "@opencode-ai/plugin" = "1.4.3";
    };
  };

  codexPackageVersion =
    if config.programs.codex.package != null then
      lib.getVersion config.programs.codex.package
    else
      "0.94.0";
  codexUseXdgDirectories =
    config.home.preferXdgDirectories && lib.versionAtLeast codexPackageVersion "0.2.0";
  codexXdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  codexConfigDir = if codexUseXdgDirectories then "${codexXdgConfigHome}/codex" else ".codex";
in
{
  meta.maintainers = [ ];

  options.programs.workmux = {
    enable = lib.mkEnableOption "workmux, a git worktree and multiplexer orchestrator";

    package = lib.mkPackageOption pkgs "workmux" { nullable = true; };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/workmux/config.yaml`.
        See <https://github.com/raine/workmux/> for supported values.
      '';
      example = lib.literalExpression ''
        {
          multiplexer = "tmux";
          default_agent = "claude";
        }
      '';
    };

    enableClaudeCodeIntegration = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to inject workmux status tracking hooks into
        {option}`programs.claude-code.settings.hooks` when
        {option}`programs.claude-code.enable` is true.
      '';
    };

    enableGeminiCliIntegration = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to inject workmux status tracking hooks into
        {option}`programs.gemini-cli.settings.hooks` when
        {option}`programs.gemini-cli.enable` is true.
      '';
    };

    enableCodexIntegration = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to install workmux status tracking hooks for Codex when
        {option}`programs.codex.enable` is true.

        Writes {file}`CODEX_HOME/hooks.json` and enables the
        `codex_hooks` feature flag in
        {option}`programs.codex.settings.features`.
      '';
    };

    enableOpencodeIntegration = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to install the workmux status tracking plugin for OpenCode
        when {option}`programs.opencode.enable` is true.

        Writes the plugin to
        {file}`$XDG_CONFIG_HOME/opencode/plugins/workmux-status.ts`
        along with a {file}`package.json` declaring the plugin dependency.
      '';
    };
  };

  config = mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile."workmux/config.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "workmux-config.yaml" cfg.settings;
      };
    }

    (mkIf (cfg.enableClaudeCodeIntegration && config.programs.claude-code.enable) {
      programs.claude-code.settings.hooks = claudeCodeHooks;
    })

    (mkIf (cfg.enableGeminiCliIntegration && config.programs.gemini-cli.enable) {
      programs.gemini-cli.settings.hooks = geminiCliHooks;
    })

    (mkIf (cfg.enableCodexIntegration && config.programs.codex.enable) {
      programs.codex.settings.features.codex_hooks = true;

      home.file."${codexConfigDir}/hooks.json".source =
        jsonFormat.generate "workmux-codex-hooks.json"
          { hooks = codexHooks; };
    })

    (mkIf (cfg.enableOpencodeIntegration && config.programs.opencode.enable) {
      xdg.configFile = {
        "opencode/plugins/workmux-status.ts".text = opencodePluginSource;
        "opencode/package.json".source =
          jsonFormat.generate "workmux-opencode-package.json"
            opencodePackageJson;
      };
    })
  ]);
}
