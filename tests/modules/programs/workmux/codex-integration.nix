{
  programs.workmux = {
    enable = true;
    package = null;
  };

  programs.codex = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/hooks.json
    assertFileRegex home-files/.codex/hooks.json '"UserPromptSubmit"'
    assertFileRegex home-files/.codex/hooks.json '"PostToolUse"'
    assertFileRegex home-files/.codex/hooks.json '"Stop"'
    assertFileRegex home-files/.codex/hooks.json 'workmux set-window-status working'
    assertFileRegex home-files/.codex/hooks.json 'workmux set-window-status done'

    assertFileExists home-files/.codex/config.toml
    assertFileRegex home-files/.codex/config.toml 'codex_hooks = true'
  '';
}
