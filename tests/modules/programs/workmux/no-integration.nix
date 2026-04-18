{
  programs.workmux = {
    enable = true;
    package = null;
    enableClaudeCodeIntegration = false;
    enableGeminiCliIntegration = false;
    enableCodexIntegration = false;
    enableOpencodeIntegration = false;
  };

  programs.claude-code = {
    enable = true;
    package = null;
  };

  programs.gemini-cli = {
    enable = true;
    package = null;
  };

  programs.codex = {
    enable = true;
    package = null;
  };

  programs.opencode.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.claude/settings.json
    assertPathNotExists home-files/.gemini/settings.json
    assertPathNotExists home-files/.codex/hooks.json
    assertPathNotExists home-files/.config/opencode/plugins/workmux-status.ts
    assertPathNotExists home-files/.config/opencode/package.json
  '';
}
