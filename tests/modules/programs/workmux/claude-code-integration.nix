{
  programs.workmux = {
    enable = true;
    package = null;
  };

  programs.claude-code = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertFileExists home-files/.claude/settings.json
    assertFileRegex home-files/.claude/settings.json '"UserPromptSubmit"'
    assertFileRegex home-files/.claude/settings.json '"Notification"'
    assertFileRegex home-files/.claude/settings.json '"permission_prompt\|elicitation_dialog"'
    assertFileRegex home-files/.claude/settings.json '"PostToolUse"'
    assertFileRegex home-files/.claude/settings.json '"Stop"'
    assertFileRegex home-files/.claude/settings.json 'workmux set-window-status working'
    assertFileRegex home-files/.claude/settings.json 'workmux set-window-status waiting'
    assertFileRegex home-files/.claude/settings.json 'workmux set-window-status done'
  '';
}
